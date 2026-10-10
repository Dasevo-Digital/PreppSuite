#include "text_recognition.h"

#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Globalization.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.Streams.h>

#include <algorithm>
#include <cstring>
#include <string>
#include <thread>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
using winrt::Windows::Globalization::Language;
using winrt::Windows::Graphics::Imaging::BitmapAlphaMode;
using winrt::Windows::Graphics::Imaging::BitmapPixelFormat;
using winrt::Windows::Graphics::Imaging::SoftwareBitmap;
using winrt::Windows::Media::Ocr::OcrEngine;
using winrt::Windows::Media::Ocr::OcrResult;

// The languages asked for, as BCP-47 tags: "de-DE", "en-US".
std::vector<std::string> LanguagesOf(const EncodableMap* arguments) {
  std::vector<std::string> languages;
  if (arguments) {
    auto found = arguments->find(EncodableValue("languages"));
    if (found != arguments->end()) {
      if (auto list = std::get_if<EncodableList>(&found->second)) {
        for (const auto& item : *list) {
          if (auto tag = std::get_if<std::string>(&item)) {
            languages.push_back(*tag);
          }
        }
      }
    }
  }
  if (languages.empty()) languages = {"de-DE", "en-US"};
  return languages;
}

// An engine for the first asked-for language Windows can read, else for
// the user's own languages, else none.
OcrEngine EngineFor(const std::vector<std::string>& languages) {
  for (const auto& tag : languages) {
    Language language{winrt::to_hstring(tag)};
    if (OcrEngine::IsLanguageSupported(language)) {
      if (auto engine = OcrEngine::TryCreateFromLanguage(language)) {
        return engine;
      }
    }
  }
  return OcrEngine::TryCreateFromUserProfileLanguages();
}

// The lines top to bottom, with a blank line where the gap above a line is
// more than one and a half of its own height -- a new block. The Dart side
// makes paragraphs of those.
std::string TextOf(const OcrResult& result) {
  std::string out;
  bool first = true;
  double previous_bottom = 0;
  for (const auto& line : result.Lines()) {
    double top = 1e9;
    double bottom = 0;
    for (const auto& word : line.Words()) {
      const auto box = word.BoundingRect();
      top = (std::min)(top, static_cast<double>(box.Y));
      bottom = (std::max)(bottom, static_cast<double>(box.Y + box.Height));
    }
    if (!first) {
      const double height = bottom - top;
      out += (top - previous_bottom) > height * 1.5 ? "\n\n" : "\n";
    }
    out += winrt::to_string(line.Text());
    previous_bottom = bottom;
    first = false;
  }
  return out;
}

}  // namespace

TextRecognition::TextRecognition(flutter::BinaryMessenger* messenger,
                                 HWND window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "de.dasevo.preppsuite/text_recognition",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) { Handle(call, std::move(result)); });
}

TextRecognition::~TextRecognition() { channel_->SetMethodCallHandler(nullptr); }

void TextRecognition::Deliver() {
  std::vector<Reply> ready;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    ready.swap(ready_);
  }
  for (auto& reply : ready) reply();
}

void TextRecognition::Handle(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* arguments = std::get_if<EncodableMap>(call.arguments());
  const auto languages = LanguagesOf(arguments);
  std::shared_ptr<flutter::MethodResult<EncodableValue>> shared =
      std::move(result);

  if (call.method_name() == "support") {
    // Asked off the window's thread too: the engine's first use loads it.
    std::thread([this, shared, languages]() {
      winrt::init_apartment(winrt::apartment_type::multi_threaded);
      std::string answer = "needsLanguagePack";
      try {
        if (EngineFor(languages)) answer = "available";
      } catch (...) {
        answer = "unsupported";
      }
      {
        std::lock_guard<std::mutex> lock(mutex_);
        ready_.push_back([shared, answer]() {
          shared->Success(EncodableValue(answer));
        });
      }
      PostMessage(window_, kDoneMessage, 0, 0);
    }).detach();
    return;
  }

  if (call.method_name() != "recognize" || !arguments) {
    shared->NotImplemented();
    return;
  }
  const auto bgra = arguments->find(EncodableValue("bgra"));
  const auto width = arguments->find(EncodableValue("width"));
  const auto height = arguments->find(EncodableValue("height"));
  if (bgra == arguments->end() || width == arguments->end() ||
      height == arguments->end()) {
    shared->Error("arguments", "no page");
    return;
  }
  auto pixels = std::get_if<std::vector<uint8_t>>(&bgra->second);
  auto w = std::get_if<int32_t>(&width->second);
  auto h = std::get_if<int32_t>(&height->second);
  if (!pixels || !w || !h || *w <= 0 || *h <= 0 ||
      pixels->size() < static_cast<size_t>(*w) * (*h) * 4) {
    shared->Error("arguments", "no page");
    return;
  }

  std::thread([this, shared, languages, page = *pixels, w = *w, h = *h]() {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    Reply reply;
    try {
      auto engine = EngineFor(languages);
      if (!engine) {
        reply = [shared]() {
          shared->Error("needsLanguagePack", "no OCR language installed");
        };
      } else {
        SoftwareBitmap bitmap(BitmapPixelFormat::Bgra8, w, h,
                              BitmapAlphaMode::Premultiplied);
        winrt::Windows::Storage::Streams::Buffer buffer(
            static_cast<uint32_t>(page.size()));
        std::memcpy(buffer.data(), page.data(), page.size());
        buffer.Length(static_cast<uint32_t>(page.size()));
        bitmap.CopyFromBuffer(buffer);
        const auto text = TextOf(engine.RecognizeAsync(bitmap).get());
        reply = [shared, text]() { shared->Success(EncodableValue(text)); };
      }
    } catch (const winrt::hresult_error& error) {
      const auto message = winrt::to_string(error.message());
      reply = [shared, message]() { shared->Error("recognition", message); };
    } catch (...) {
      reply = [shared]() { shared->Error("recognition", "failed"); };
    }
    {
      std::lock_guard<std::mutex> lock(mutex_);
      ready_.push_back(std::move(reply));
    }
    PostMessage(window_, kDoneMessage, 0, 0);
  }).detach();
}
