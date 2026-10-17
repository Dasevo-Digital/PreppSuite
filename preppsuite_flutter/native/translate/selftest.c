// Loads a direction, translates, and says how long it took.
//
//   translate_selftest <model> <lex> <vocab> "Text" [<model2> <lex2> <vocab2>]
//
// The second triple makes it pivot through English. Used to measure stage
// 0 of #182 and, after a build, to see that the library loads at all.
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "translate.h"

static double now(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec + t.tv_nsec / 1e9;
}

static PtModel* open_model(const char* m, const char* l, const char* v) {
  double start = now();
  PtModel* model = pt_model_open(m, l, v);
  if (pt_model_error(model)[0]) {
    fprintf(stderr, "open failed: %s\n", pt_model_error(model));
    exit(1);
  }
  fprintf(stderr, "loaded in %.2f s\n", now() - start);
  return model;
}

int main(int argc, char** argv) {
  if (argc != 5 && argc != 8) {
    fprintf(stderr, "usage: %s model lex vocab text [model2 lex2 vocab2]\n",
            argv[0]);
    return 2;
  }
  PtModel* first = open_model(argv[1], argv[2], argv[3]);
  PtModel* second = argc == 8 ? open_model(argv[5], argv[6], argv[7]) : NULL;
  for (int round = 0; round < 2; round++) {
    double start = now();
    char* out = pt_translate(first, second, argv[4]);
    if (!out) {
      fprintf(stderr, "translate failed: %s\n", pt_last_error());
      return 1;
    }
    fprintf(stderr, "translated in %.3f s\n", now() - start);
    if (round == 1) printf("%s\n", out);
    pt_string_free(out);
  }
  pt_model_close(second);
  pt_model_close(first);
  return 0;
}
