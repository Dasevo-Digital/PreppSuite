// A C surface over libxapian, wide enough for exactly one job: searching
// the full-text index that a ZIM archive already carries inside it.
//
// C rather than C++ because Dart's FFI can only call the former, and
// deliberately narrow: no Xapian type crosses the boundary, no callback
// goes the other way, and every string the caller sees is owned by the
// searcher. That keeps the Dart side free of manual memory management —
// the only thing it has to release is the searcher itself.
#ifndef ZIM_XAPIAN_H
#define ZIM_XAPIAN_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// The library is built with hidden visibility so that nothing but this
// surface leaves it — Xapian's own symbols stay inside, which keeps the
// shared library small and its ABI exactly this file.
#ifdef _WIN32
#define ZX_EXPORT __declspec(dllexport)
#else
#define ZX_EXPORT __attribute__((visibility("default")))
#endif

typedef struct ZxSearcher ZxSearcher;

// Opens the Xapian index embedded in a ZIM archive.
//
// `offset` is where the index blob starts in the file — Xapian reads a
// single-file database from the descriptor's current position, which is
// what lets the index be used where it lies instead of being copied out
// of a multi-gigabyte archive.
//
// Never returns NULL: a failure comes back as a handle whose zx_error is
// set, so the caller has exactly one cleanup path.
ZX_EXPORT ZxSearcher* zx_open_path(const char* path, int64_t offset);

// As above, but adopts an already-open descriptor — the only way in on
// Android, where the archive is a `content://` document and there is no
// path to open. Ownership passes to the searcher either way: Xapian
// closes the descriptor, including when opening fails.
ZX_EXPORT ZxSearcher* zx_open_fd(int fd, int64_t offset);

ZX_EXPORT void zx_close(ZxSearcher* searcher);

// The last failure, or "" when there was none.
ZX_EXPORT const char* zx_error(ZxSearcher* searcher);

// The index's own language tag, as the archive recorded it. Empty when
// it records none, in which case no stemmer was applied.
ZX_EXPORT const char* zx_language(ZxSearcher* searcher);

// Whether document data carries a namespace prefix ("C/Trinkwasser") or
// is a bare URL in the old article namespace.
ZX_EXPORT int32_t zx_has_full_paths(ZxSearcher* searcher);

ZX_EXPORT int32_t zx_document_count(ZxSearcher* searcher);

// Runs a query and keeps its results until the next call. Returns the
// number of results held, or -1 on failure.
ZX_EXPORT int32_t zx_search(ZxSearcher* searcher, const char* query, int32_t offset,
                  int32_t limit);

// Xapian's estimate of how many documents match in total, which is what
// a result count in the UI can be built from.
ZX_EXPORT int32_t zx_estimated_matches(ZxSearcher* searcher);

// Valid until the next zx_search or zx_close. Out-of-range gives "".
ZX_EXPORT const char* zx_result_path(ZxSearcher* searcher, int32_t index);

// The passage the match was found in, when the archive stored one.
// Current Kiwix archives do not — they keep only a lowercased sort title
// and a word count — so this is usually empty and the caller shows the
// article's own text instead.
ZX_EXPORT const char* zx_result_snippet(ZxSearcher* searcher, int32_t index);

#ifdef __cplusplus
}
#endif

#endif  // ZIM_XAPIAN_H
