# Fetches Mozilla's translation engine at a fixed commit, with what it
# needs and nothing else, and makes it build with current compilers.
# Sourced by the build_*.sh beside it; prints the engine directory.
#
# The engine is `inference/` of mozilla/translations -- the copy Mozilla
# keeps up, which Firefox's translations are built from. The older
# browsermt/bergamot-translator stopped in 2024. Fetched as a sparse
# checkout of one commit, with only the submodules a CPU build reads:
# FBGEMM, the CUDA and WebAssembly parts and the websocket server stay out.
#
# Six places are changed after the checkout, each because a newer
# compiler, an SDK or mingw refuses what another let through. None changes
# what the engine computes:
#
#   * SentencePiece casts -1 to an enum in a constexpr, which clang 16 and
#     later reject; `const` is what it means.
#   * Marian compiles with -Werror, so every warning a new compiler adds
#     stops the build. The warnings stay; they no longer fail it.
#   * Marian's bundled zlib 1.2.11 defines fdopen away on anything
#     Apple, which collides with the macOS SDK's own declaration; zlib
#     1.2.12 narrowed that to the classic Mac OS, and so does this.
#   * Marian's architecture check knows PowerPC, i386 and x86_64 as macOS
#     architectures and stops at arm64, which Apple has shipped since
#     2020. It is let through, and Marian's own "arm" branch takes over.
#   * The Windows call stack printer annotates one function pointer type
#     with MSVC's __in and __out, which mean nothing to the compiler and
#     which mingw does not define. They are dropped.
#   * Bergamot's aligned buffer asks whether the compiler is MSVC where it
#     means whether the system is Windows: only Windows has
#     _aligned_malloc, and only POSIX has posix_memalign. The two places
#     that allocate and free ask for _WIN32 now, which MSVC defines as
#     well; the include of MSVC's own runtime header stays as it was.
#
# Each change is made only where the old text is still there, so a second
# run leaves the files -- and their times -- alone and Ninja rebuilds
# nothing.
#
# PCRE2 for the sentence splitter is placed beside it from a tarball with
# a pinned checksum. Left to itself the engine downloads it at build time
# and checks nothing -- the same gap tool/pdfium_provenance.sh closes for
# PDFium -- or links whatever the build machine has, which on this Mac
# was Homebrew's headers and a library only the newest macOS carries.

readonly TRANSLATE_REPO="https://github.com/mozilla/translations.git"
readonly TRANSLATE_COMMIT="69455acaecbe8650cdba988dbcf7c10ca20e7c48"
readonly PCRE2_VERSION="10.39"
readonly PCRE2_SHA256="0781bd2536ef5279b1943471fdcdbd9961a2845e1d2c9ad849b9bd98ba1a9bd4"

translate_source() {
  local work="$1"
  local repo="$work/translations"
  local engine="$repo/inference"
  if [ -f "$work/.source-ready-$TRANSLATE_COMMIT" ]; then
    translate_patch "$engine" >&2 || return 1
    echo "$engine"
    return
  fi

  # Every step returns on failure by hand: this runs in a command
  # substitution, where the callers' set -e does not reach. Without it a
  # clone that timed out went on to the tarball, and when that one came
  # through, the marker below told every later run that the sources were
  # there -- each then stopped at "patch spm failed" (#227).
  rm -rf "$repo"
  git clone --quiet --filter=blob:none --no-checkout "$TRANSLATE_REPO" "$repo" >&2 ||
    return 1
  git -C "$repo" sparse-checkout set inference >&2 || return 1
  git -C "$repo" checkout --quiet "$TRANSLATE_COMMIT" >&2 || return 1
  git -C "$repo" submodule update --init --quiet \
    inference/3rd_party/ssplit-cpp \
    inference/marian-fork/src/3rd_party/intgemm \
    inference/marian-fork/src/3rd_party/sentencepiece \
    inference/marian-fork/src/3rd_party/simd_utils >&2 || return 1
  git -C "$repo" submodule update --init --recursive --quiet \
    inference/marian-fork/src/3rd_party/ruy >&2 || return 1

  local pcre_dir="$engine/3rd_party/ssplit-cpp/src/3rd-party"
  local tarball="$work/pcre2-$PCRE2_VERSION.tar.gz"
  if [ ! -f "$tarball" ]; then
    curl --fail --silent --show-error --location -o "$tarball.part" \
      "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE2_VERSION/pcre2-$PCRE2_VERSION.tar.gz" >&2 ||
      { rm -f "$tarball.part"; return 1; }
    mv "$tarball.part" "$tarball" || return 1
  fi
  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$tarball" | cut -d' ' -f1)"
  else
    actual="$(shasum -a 256 "$tarball" | cut -d' ' -f1)"
  fi
  if [ "$actual" != "$PCRE2_SHA256" ]; then
    echo "pcre2 checksum mismatch: $actual" >&2
    rm -f "$tarball"
    return 1
  fi
  mkdir -p "$pcre_dir" || return 1
  tar -xzf "$tarball" -C "$pcre_dir" || return 1

  touch "$work/.source-ready-$TRANSLATE_COMMIT"
  translate_patch "$engine" >&2 || return 1
  echo "$engine"
}

# The changes described at the top, each only where it is still due.
translate_patch() {
  local engine="$1"
  local spm="$engine/marian-fork/src/3rd_party/sentencepiece/src/trainer_interface.cc"
  local marian="$engine/marian-fork/CMakeLists.txt"
  local zutil="$engine/marian-fork/src/3rd_party/zlib/zutil.h"
  local arch="$engine/marian-fork/cmake/TargetArch.cmake"
  local stack="$engine/marian-fork/src/3rd_party/ExceptionWithCallStack.cpp"
  local aligned="$engine/src/translator/aligned.h"
  grep -q "  constexpr unicode_script::ScriptType kAnyType =" "$spm" &&
    perl -0pi -e 's/  constexpr unicode_script::ScriptType kAnyType =/  const unicode_script::ScriptType kAnyType =/' "$spm"
  grep -q "ALL_WARNINGS -Wall; -Werror; -Wextra;" "$marian" &&
    perl -0pi -e 's/list\(APPEND ALL_WARNINGS -Wall; -Werror; -Wextra;/list(APPEND ALL_WARNINGS -Wall; -Wextra;/' "$marian"
  grep -q "^#if defined(MACOS) || defined(TARGET_OS_MAC)$" "$zutil" &&
    perl -0pi -e 's/^#if defined\(MACOS\) \|\| defined\(TARGET_OS_MAC\)$/#if defined(MACOS)/m' "$zutil"
  grep -q "list(APPEND ARCH arm64)" "$arch" ||
    perl -0pi -e 's/(            elseif\("\$\{osx_arch\}" STREQUAL "x86_64"\)\n                set\(osx_arch_x86_64 TRUE\)\n)/$1            elseif("\$\{osx_arch\}" STREQUAL "arm64")\n                set(osx_arch_arm64 TRUE)\n/; s/(        if\(osx_arch_x86_64\)\n            list\(APPEND ARCH x86_64\)\n        endif\(\)\n)/$1\n        if(osx_arch_arm64)\n            list(APPEND ARCH arm64)\n        endif()\n/' "$arch"
  grep -q "__in ULONG" "$stack" &&
    perl -0pi -e 's/\(__in ULONG, __in ULONG, __out PVOID\*, __out_opt PULONG\)/(ULONG, ULONG, PVOID*, PULONG)/' "$stack"
  perl -0ne 'exit(/#ifdef _MSC_VER\n\s*mem_ = static_cast<T\*>\(_aligned_malloc/ ? 0 : 1)' "$aligned" &&
    perl -0pi -e 's/#ifdef _MSC_VER(\n\s*mem_ = static_cast<T\*>\(_aligned_malloc)/#ifdef _WIN32$1/; s/#ifdef _MSC_VER(\n\s*_aligned_free\(mem_\);)/#ifdef _WIN32$1/' "$aligned"
  grep -q "const unicode_script::ScriptType kAnyType" "$spm" || { echo "patch spm failed"; return 1; }
  grep -q "ALL_WARNINGS -Wall; -Wextra;" "$marian" || { echo "patch marian failed"; return 1; }
  grep -q "^#if defined(MACOS)$" "$zutil" || { echo "patch zlib failed"; return 1; }
  grep -q "list(APPEND ARCH arm64)" "$arch" || { echo "patch arch failed"; return 1; }
  grep -q "(ULONG, ULONG, PVOID\*, PULONG)" "$stack" || { echo "patch stack failed"; return 1; }
  [ "$(grep -c "^#ifdef _WIN32$" "$aligned")" -eq 2 ] || { echo "patch aligned failed"; return 1; }
}
