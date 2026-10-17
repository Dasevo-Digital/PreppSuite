#include "translate.h"

#include <cstdlib>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "common/logging.h"
#include "translator/parser.h"
#include "translator/response.h"
#include "translator/service.h"
#include "translator/translation_model.h"

using marian::bergamot::BlockingService;
using marian::bergamot::Response;
using marian::bergamot::ResponseOptions;
using marian::bergamot::TranslationModel;

struct PtModel {
  std::shared_ptr<TranslationModel> model;
  std::string error;
};

namespace {

// The settings Firefox gives the same models (translations-engine), so a
// sentence comes out as it would there: greedy decoding, int8 matrices
// with the model's own scaling, and the shortlist limiting what the
// decoder considers.
std::string configFor(const char* model, const char* lex, const char* vocab) {
  return std::string("models:\n  - ") + model +
         "\nvocabs:\n  - " + vocab + "\n  - " + vocab +
         "\nshortlist:\n  - " + lex + "\n  - false\n"
         "beam-size: 1\n"
         "normalize: 1.0\n"
         "word-penalty: 0\n"
         "max-length-break: 128\n"
         "mini-batch-words: 1024\n"
         "workspace: 128\n"
         "max-length-factor: 2.0\n"
         "skip-cost: true\n"
         "cpu-threads: 0\n"
         "quiet: true\n"
         "quiet-translation: true\n"
         "gemm-precision: int8shiftAlphaAll\n"
         "ssplit-mode: paragraph\n";
}

// Marian's ABORT calls std::abort() unless told otherwise, and inside an
// app that would take the whole app down over one unreadable file.
void throwInsteadOfAborting() {
  static std::once_flag once;
  std::call_once(once, [] { marian::setThrowExceptionOnAbort(true); });
}

std::mutex& serviceLock() {
  static std::mutex lock;
  return lock;
}

BlockingService& service() {
  static BlockingService instance{BlockingService::Config{}};
  return instance;
}

thread_local std::string lastError;

}  // namespace

extern "C" {

PtModel* pt_model_open(const char* model_path, const char* lex_path,
                       const char* vocab_path) {
  throwInsteadOfAborting();
  auto* handle = new PtModel();
  if (!model_path || !lex_path || !vocab_path) {
    handle->error = "missing path";
    return handle;
  }
  try {
    auto options = marian::bergamot::parseOptionsFromString(
        configFor(model_path, lex_path, vocab_path), /*validate=*/false);
    handle->model = std::make_shared<TranslationModel>(options);
  } catch (const std::exception& e) {
    handle->error = e.what();
    if (handle->error.empty()) handle->error = "model could not be loaded";
  } catch (...) {
    handle->error = "model could not be loaded";
  }
  return handle;
}

const char* pt_model_error(PtModel* model) {
  return model ? model->error.c_str() : "no model";
}

void pt_model_close(PtModel* model) { delete model; }

char* pt_translate(PtModel* first, PtModel* second, const char* text) {
  throwInsteadOfAborting();
  lastError.clear();
  if (!first || !first->model || (second && !second->model) || !text) {
    lastError = "model not loaded";
    return nullptr;
  }
  try {
    std::vector<std::string> sources{std::string(text)};
    std::vector<ResponseOptions> options(1);
    std::vector<Response> responses;
    {
      std::lock_guard<std::mutex> guard(serviceLock());
      responses = second ? service().pivotMultiple(first->model, second->model,
                                                   std::move(sources), options)
                         : service().translateMultiple(
                               first->model, std::move(sources), options);
    }
    const std::string& out = responses.at(0).getTranslatedText();
    char* copy = static_cast<char*>(std::malloc(out.size() + 1));
    if (!copy) {
      lastError = "out of memory";
      return nullptr;
    }
    std::memcpy(copy, out.c_str(), out.size() + 1);
    return copy;
  } catch (const std::exception& e) {
    lastError = e.what();
  } catch (...) {
    lastError = "translation failed";
  }
  if (lastError.empty()) lastError = "translation failed";
  return nullptr;
}

void pt_string_free(char* text) { std::free(text); }

const char* pt_last_error(void) { return lastError.c_str(); }

}  // extern "C"
