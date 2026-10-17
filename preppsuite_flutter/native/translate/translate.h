// A C surface over Mozilla's Bergamot translator, wide enough for exactly
// one job: translating plain text offline with the models Firefox uses
// (#182).
//
// C rather than C++ because Dart's FFI can only call the former, and
// narrow on purpose: no Bergamot type crosses the boundary and no
// callback goes the other way. The caller owns two kinds of thing -- a
// model, closed with pt_model_close, and a translated string, released
// with pt_string_free -- and nothing else.
#ifndef PREPPSUITE_TRANSLATE_H
#define PREPPSUITE_TRANSLATE_H

#ifdef __cplusplus
extern "C" {
#endif

// Built with hidden visibility, so that nothing but this surface leaves
// the library: Marian's own symbols stay inside it.
#ifdef _WIN32
#define PT_EXPORT __declspec(dllexport)
#else
#define PT_EXPORT __attribute__((visibility("default")))
#endif

typedef struct PtModel PtModel;

// Loads one direction -- German to English, say -- from its three files:
// the quantised model, the lexical shortlist and the SentencePiece
// vocabulary, as Firefox downloads them.
//
// Never returns NULL: a failure comes back as a model whose
// pt_model_error is set, so the caller has one cleanup path.
PT_EXPORT PtModel* pt_model_open(const char* model_path, const char* lex_path,
                                 const char* vocab_path);

// The failure that opening ran into, or "" when there was none.
PT_EXPORT const char* pt_model_error(PtModel* model);

PT_EXPORT void pt_model_close(PtModel* model);

// Translates UTF-8 [text] with [first], and then with [second] when it is
// not NULL: German to Arabic is German to English to Arabic, because the
// models are trained against English.
//
// Returns a new string the caller releases with pt_string_free, or NULL
// on failure, with the reason in pt_last_error. Blocks; one call at a
// time is served, the rest wait.
PT_EXPORT char* pt_translate(PtModel* first, PtModel* second,
                             const char* text);

PT_EXPORT void pt_string_free(char* text);

// Why the last pt_translate on this thread failed, or "".
PT_EXPORT const char* pt_last_error(void);

#ifdef __cplusplus
}
#endif

#endif
