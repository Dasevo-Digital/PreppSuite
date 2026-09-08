// Checks a freshly built shim without Flutter in the way.
//
// A new platform's build has three ways to be wrong that a compiler
// cannot see: the file opens in text mode, the seek is 32 bits wide, or
// the library links but exports nothing. All three come out here, and on
// a machine where there is no Dart to run.
//
//   selftest <archive.zim> <offset> [query]
//
// The offset is where the archive says its index begins — the number the
// live test in test/live/xapian_speed_test.dart prints.
#include <stdio.h>
#include <stdlib.h>

#include "zim_xapian.h"

int main(int argc, char** argv) {
  if (argc < 3) {
    fprintf(stderr, "usage: selftest <archive.zim> <offset> [query]\n");
    return 2;
  }

  const char* path = argv[1];
  const long long offset = atoll(argv[2]);
  const char* query = argc > 3 ? argv[3] : "wasser";

  ZxSearcher* searcher = zx_open_path(path, (int64_t)offset);
  const char* problem = zx_error(searcher);
  if (problem != NULL && problem[0] != '\0') {
    printf("FEHLER beim Oeffnen: %s\n", problem);
    zx_close(searcher);
    return 1;
  }

  printf("Dokumente  %d\n", zx_document_count(searcher));
  printf("Sprache    %s\n", zx_language(searcher));
  printf("Pfade      %s\n",
         zx_has_full_paths(searcher) ? "mit Namensraum" : "blanke URL");

  const int32_t found = zx_search(searcher, query, 0, 5);
  if (found < 0) {
    printf("FEHLER bei der Suche: %s\n", zx_error(searcher));
    zx_close(searcher);
    return 1;
  }

  printf("%s: %d Treffer geschaetzt, %d geholt\n", query,
         zx_estimated_matches(searcher), found);
  for (int32_t at = 0; at < found; at++) {
    printf("  %s\n", zx_result_path(searcher, at));
  }

  zx_close(searcher);
  // No hits is a failure here: this runs against an archive that was
  // chosen to have some, so an empty answer means the index was not
  // really read.
  return found > 0 ? 0 : 1;
}
