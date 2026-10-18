/// The offline translator, through the native shim in `native/translate`
/// (#182).
///
/// Every translation runs on an isolate of its own: the native call
/// blocks, and a paragraph takes from a few hundredths of a second on a
/// desktop to rather more on an old phone. The models are opened for the
/// call and closed after it. Opening one measured 0.03 s on a Mac, which is
/// cheaper than keeping two directions of 35 MB each and the engine's
/// working memory resident for a screen opened now and then.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'translator_store.dart';

/// Whether this build carries the translator library at all.
///
/// It is optional: a build without it runs, and the translator screen
/// says the translator is not part of it.
bool get translatorAvailable {
  try {
    _bindings;
    return true;
  } on Object {
    return false;
  }
}

/// Translates [text] through [packs] in order -- one for a direction to
/// or from English, two by way of English.
Future<String> translateText(
  String text,
  List<InstalledTranslatorPack> packs,
) {
  if (packs.isEmpty || packs.length > 2) {
    throw ArgumentError.value(packs.length, 'packs', 'one or two');
  }
  final paths = [
    for (final pack in packs) [pack.modelPath, pack.lexPath, pack.vocabPath],
  ];
  return Isolate.run(() => _translateNow(text, paths));
}

String _translateNow(String text, List<List<String>> paths) {
  final opened = <Pointer<_PtModel>>[];
  final allocated = <Pointer<Utf8>>[];
  Pointer<Utf8> native(String value) {
    final pointer = value.toNativeUtf8();
    allocated.add(pointer);
    return pointer;
  }

  try {
    for (final [model, lex, vocab] in paths) {
      final handle = _bindings.open(native(model), native(lex), native(vocab));
      opened.add(handle);
      final problem = _bindings.modelError(handle).toDartString();
      if (problem.isNotEmpty) throw TranslatorException(problem);
    }
    final result = _bindings.translate(
      opened.first,
      opened.length == 2 ? opened.last : nullptr,
      native(text),
    );
    if (result == nullptr) {
      throw TranslatorException(_bindings.lastError().toDartString());
    }
    try {
      return result.toDartString();
    } finally {
      _bindings.free(result);
    }
  } finally {
    for (final handle in opened) {
      _bindings.close(handle);
    }
    for (final pointer in allocated) {
      calloc.free(pointer);
    }
  }
}

class TranslatorException implements Exception {
  const TranslatorException(this.message);

  final String message;

  @override
  String toString() => 'TranslatorException: $message';
}

// --- The binding ------------------------------------------------------

final class _PtModel extends Opaque {}

_Bindings? _cached;

_Bindings get _bindings => _cached ??= _Bindings(_openLibrary());

/// Looks in order: told to us, bundled with the app, on the loader's
/// path, or in the build directory of a working copy.
DynamicLibrary _openLibrary() {
  final name = Platform.isWindows
      ? 'preppsuite_translate.dll'
      : Platform.isMacOS || Platform.isIOS
      ? 'libpreppsuite_translate.dylib'
      : 'libpreppsuite_translate.so';

  final candidates = [
    ?Platform.environment['PREPPSUITE_TRANSLATE_LIBRARY'],
    ?_bundled(name),
    name,
    'native/translate/build/$name',
  ];

  for (final candidate in candidates) {
    try {
      return DynamicLibrary.open(candidate);
    } on ArgumentError {
      continue;
    }
  }
  throw TranslatorException('$name was not found');
}

String? _bundled(String name) {
  final beside = File(Platform.resolvedExecutable).parent;
  if (Platform.isMacOS) return '${beside.parent.path}/Frameworks/$name';
  if (Platform.isLinux) return '${beside.path}/lib/$name';
  if (Platform.isWindows) return '${beside.path}\\$name';
  return null;
}

/// Hand-written: six functions against a header this repository owns.
class _Bindings {
  _Bindings(DynamicLibrary library)
    : open = library
          .lookup<
            NativeFunction<
              Pointer<_PtModel> Function(
                Pointer<Utf8>,
                Pointer<Utf8>,
                Pointer<Utf8>,
              )
            >
          >('pt_model_open')
          .asFunction(),
      modelError = library
          .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<_PtModel>)>>(
            'pt_model_error',
          )
          .asFunction(),
      close = library
          .lookup<NativeFunction<Void Function(Pointer<_PtModel>)>>(
            'pt_model_close',
          )
          .asFunction(),
      translate = library
          .lookup<
            NativeFunction<
              Pointer<Utf8> Function(
                Pointer<_PtModel>,
                Pointer<_PtModel>,
                Pointer<Utf8>,
              )
            >
          >('pt_translate')
          .asFunction(),
      free = library
          .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>(
            'pt_string_free',
          )
          .asFunction(),
      lastError = library
          .lookup<NativeFunction<Pointer<Utf8> Function()>>('pt_last_error')
          .asFunction();

  final Pointer<_PtModel> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
  open;
  final Pointer<Utf8> Function(Pointer<_PtModel>) modelError;
  final void Function(Pointer<_PtModel>) close;
  final Pointer<Utf8> Function(
    Pointer<_PtModel>,
    Pointer<_PtModel>,
    Pointer<Utf8>,
  )
  translate;
  final void Function(Pointer<Utf8>) free;
  final Pointer<Utf8> Function() lastError;
}
