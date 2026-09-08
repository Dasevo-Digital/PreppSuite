#include "zim_xapian.h"

#include <fcntl.h>

#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif

#include <cstdlib>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include <xapian.h>

namespace {

// Opening the archive, in the two ways the platforms spell it.
//
// Two things go wrong on Windows if this is left as plain POSIX. A file
// opened without O_BINARY is read in text mode, which rewrites bytes on
// the way past - fatal for a database. And `lseek` there takes a 32-bit
// offset, while the index in a full Wikipedia starts at byte
// 47 677 531 029: the seek would silently land somewhere else entirely.
#ifdef _WIN32
inline int zx_open_read(const char* path) {
  return ::_open(path, _O_RDONLY | _O_BINARY);
}
inline int64_t zx_seek(int fd, int64_t offset) {
  return ::_lseeki64(fd, offset, SEEK_SET);
}
inline void zx_close_fd(int fd) { ::_close(fd); }
#else
inline int zx_open_read(const char* path) { return ::open(path, O_RDONLY); }
inline int64_t zx_seek(int fd, int64_t offset) {
  // off_t is 64 bit everywhere this is built, which the build scripts
  // guarantee on 32-bit systems with _FILE_OFFSET_BITS=64.
  return ::lseek(fd, static_cast<off_t>(offset), SEEK_SET);
}
inline void zx_close_fd(int fd) { ::close(fd); }
#endif

struct Result {
  std::string path;
  std::string snippet;
};

// Kiwix records the language as an ISO 639-3 code; Xapian names its
// stemmers in English or takes a two-letter code. Only the languages
// with a Snowball stemmer are worth mapping — anything else falls
// through and the index is searched unstemmed, which still works.
const std::map<std::string, std::string>& stemmer_names() {
  static const std::map<std::string, std::string> names = {
      {"ara", "arabic"},    {"cat", "catalan"},    {"dan", "danish"},
      {"deu", "german"},    {"ger", "german"},     {"ell", "greek"},
      {"gre", "greek"},     {"eng", "english"},    {"spa", "spanish"},
      {"eus", "basque"},    {"baq", "basque"},     {"fin", "finnish"},
      {"fra", "french"},    {"fre", "french"},     {"hin", "hindi"},
      {"hun", "hungarian"}, {"hye", "armenian"},   {"arm", "armenian"},
      {"ind", "indonesian"},{"ita", "italian"},    {"lit", "lithuanian"},
      {"nep", "nepali"},    {"nld", "dutch"},      {"dut", "dutch"},
      {"nor", "norwegian"}, {"por", "portuguese"}, {"ron", "romanian"},
      {"rum", "romanian"},  {"rus", "russian"},    {"srp", "serbian"},
      {"swe", "swedish"},   {"tam", "tamil"},      {"tur", "turkish"},
  };
  return names;
}

// "title:0;wordcount:1;snippet:2" — the map the archive writes to say
// which value slot holds what. Older archives write none at all.
std::map<std::string, int> parse_values_map(const std::string& raw) {
  std::map<std::string, int> slots;
  size_t from = 0;
  while (from <= raw.size()) {
    const size_t end = raw.find(';', from);
    const std::string entry =
        raw.substr(from, end == std::string::npos ? std::string::npos : end - from);
    const size_t colon = entry.find(':');
    if (colon != std::string::npos) {
      slots[entry.substr(0, colon)] = std::atoi(entry.substr(colon + 1).c_str());
    }
    if (end == std::string::npos) break;
    from = end + 1;
  }
  return slots;
}

}  // namespace

struct ZxSearcher {
  Xapian::Database db;
  Xapian::QueryParser parser;
  // The parser keeps a bare pointer to its stopper, so the stopper has to
  // outlive it rather than the local it was built in.
  std::unique_ptr<Xapian::SimpleStopper> stopper;

  std::string error;
  std::string language;
  bool full_paths = false;

  std::map<std::string, int> value_slots;
  std::vector<Result> results;
  int32_t estimated = 0;

  // Kept so a result's fields can be handed back as `const char*`.
  std::string empty;
};

namespace {

// Everything the two entry points share once a descriptor is open.
void configure(ZxSearcher* searcher) {
  Xapian::Database& db = searcher->db;

  searcher->language = db.get_metadata("language");
    // The archive names the key "data"; libzim calls the value it reads
  // from it dbDataType, which is not the same thing.
  searcher->full_paths = db.get_metadata("data") == "fullPath";
  searcher->value_slots = parse_values_map(db.get_metadata("valuesmap"));

  searcher->parser.set_database(db);
  // Every word has to appear. Kiwix searches the same way, and on an
  // encyclopedia the alternative returns the whole archive.
  searcher->parser.set_default_op(Xapian::Query::OP_AND);

  if (!searcher->language.empty()) {
    const auto named = stemmer_names().find(searcher->language);
    const std::string name =
        named != stemmer_names().end() ? named->second : searcher->language;
    try {
      searcher->parser.set_stemmer(Xapian::Stem(name));
      // STEM_ALL rather than STEM_SOME: the index was built stemmed
      // throughout, so leaving capitalised words alone would make proper
      // nouns unfindable.
      searcher->parser.set_stemming_strategy(Xapian::QueryParser::STEM_ALL);
    } catch (const Xapian::Error&) {
      // No stemmer for this language. Unstemmed search still works.
    }
  }

  const std::string stopwords = db.get_metadata("stopwords");
  if (!stopwords.empty()) {
    searcher->stopper = std::make_unique<Xapian::SimpleStopper>();
    size_t from = 0;
    while (from < stopwords.size()) {
      const size_t end = stopwords.find('\n', from);
      const std::string word = stopwords.substr(
          from, end == std::string::npos ? std::string::npos : end - from);
      if (!word.empty()) searcher->stopper->add(word);
      if (end == std::string::npos) break;
      from = end + 1;
    }
    searcher->parser.set_stopper(searcher->stopper.get());
  }
}

ZxSearcher* open_descriptor(int fd, int64_t offset) {
  auto* searcher = new ZxSearcher();
  if (fd < 0) {
    searcher->error = "the archive could not be opened";
    return searcher;
  }

  if (zx_seek(fd, offset) < 0) {
    zx_close_fd(fd);
    searcher->error = "the index does not start where the archive says";
    return searcher;
  }

  try {
    // Reads a single-file database from wherever the descriptor happens
    // to be, which is the whole reason this works without unpacking: the
    // index is used where it lies inside the archive. Xapian takes the
    // descriptor over, and closes it itself when this throws.
    searcher->db = Xapian::Database(fd);
    configure(searcher);
  } catch (const Xapian::Error& error) {
    searcher->error = error.get_description();
  } catch (const std::exception& error) {
    searcher->error = error.what();
  }
  return searcher;
}

std::string value_of(const ZxSearcher* searcher, const Xapian::Document& document,
                     const char* name, int legacy_slot) {
  const auto slot = searcher->value_slots.find(name);
  if (slot != searcher->value_slots.end()) {
    return document.get_value(slot->second);
  }
  // Archives from before the map existed put these at fixed slots.
  if (searcher->value_slots.empty() && legacy_slot >= 0) {
    return document.get_value(legacy_slot);
  }
  return std::string();
}

}  // namespace

extern "C" {

ZxSearcher* zx_open_path(const char* path, int64_t offset) {
  return open_descriptor(zx_open_read(path), offset);
}

ZxSearcher* zx_open_fd(int fd, int64_t offset) {
  return open_descriptor(fd, offset);
}

void zx_close(ZxSearcher* searcher) { delete searcher; }

const char* zx_error(ZxSearcher* searcher) { return searcher->error.c_str(); }

const char* zx_language(ZxSearcher* searcher) {
  return searcher->language.c_str();
}

int32_t zx_has_full_paths(ZxSearcher* searcher) {
  return searcher->full_paths ? 1 : 0;
}

int32_t zx_document_count(ZxSearcher* searcher) {
  try {
    return static_cast<int32_t>(searcher->db.get_doccount());
  } catch (const Xapian::Error&) {
    return 0;
  }
}

int32_t zx_search(ZxSearcher* searcher, const char* query, int32_t offset,
                  int32_t limit) {
  searcher->results.clear();
  searcher->estimated = 0;
  searcher->error.clear();

  try {
    Xapian::Enquire enquire(searcher->db);
    enquire.set_query(searcher->parser.parse_query(query));

    const Xapian::MSet matches = enquire.get_mset(offset, limit);
    searcher->estimated = static_cast<int32_t>(matches.get_matches_estimated());

    for (auto match = matches.begin(); match != matches.end(); ++match) {
      const Xapian::Document document = match.get_document();
      // No title: the slot an archive names "title" holds a lowercased
      // sort key, not something to show. The entry the path resolves to
      // has the real one.
      searcher->results.push_back({
          document.get_data(),
          // Slot 1 in an archive with no map at all: what Kiwix wrote
          // before it started naming its slots.
          value_of(searcher, document, "snippet", 1),
      });
    }
    return static_cast<int32_t>(searcher->results.size());
  } catch (const Xapian::Error& error) {
    searcher->error = error.get_description();
    return -1;
  } catch (const std::exception& error) {
    searcher->error = error.what();
    return -1;
  }
}

int32_t zx_estimated_matches(ZxSearcher* searcher) { return searcher->estimated; }

const char* zx_result_path(ZxSearcher* searcher, int32_t index) {
  if (index < 0 || index >= static_cast<int32_t>(searcher->results.size())) {
    return searcher->empty.c_str();
  }
  return searcher->results[index].path.c_str();
}

const char* zx_result_snippet(ZxSearcher* searcher, int32_t index) {
  if (index < 0 || index >= static_cast<int32_t>(searcher->results.size())) {
    return searcher->empty.c_str();
  }
  return searcher->results[index].snippet.c_str();
}

}  // extern "C"
