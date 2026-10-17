# The translator shim around Mozilla's inference engine (#182).
#
# The engine is added as a subdirectory from wherever translate_source.sh
# put it, and linked in statically: the library inside the app has to
# carry what it needs, as the Xapian shim does.
cmake_minimum_required(VERSION 3.16)
project(preppsuite_translate C CXX)

set(BERGAMOT_SOURCE "" CACHE PATH "inference/ directory of mozilla/translations")
if(NOT EXISTS "${BERGAMOT_SOURCE}/CMakeLists.txt")
  message(FATAL_ERROR "BERGAMOT_SOURCE does not point at the engine")
endif()

# CPU only, no tests, no WASM, no Python -- the engine's own defaults
# reach for all of those.
set(COMPILE_CPU ON CACHE BOOL "" FORCE)
set(COMPILE_CUDA OFF CACHE BOOL "" FORCE)
set(COMPILE_TESTS OFF CACHE BOOL "" FORCE)
set(COMPILE_WASM OFF CACHE BOOL "" FORCE)
set(COMPILE_PYTHON OFF CACHE BOOL "" FORCE)
set(GIT_SUBMODULE OFF CACHE BOOL "" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# On ARM, Marian compiles its SIMD helpers with ARM, FMA and SSE defined
# and lax vector conversions -- but only inside its own directory, while
# the engine's translator sources beside it include the same headers.
# Set once up here, both see the same thing.
# On a Mac the target is CMAKE_OSX_ARCHITECTURES: CMAKE_SYSTEM_PROCESSOR
# names the machine doing the building, which an Intel build on Apple
# silicon is not.
if(APPLE AND CMAKE_OSX_ARCHITECTURES)
  set(TRANSLATE_TARGET_ARCH "${CMAKE_OSX_ARCHITECTURES}")
else()
  set(TRANSLATE_TARGET_ARCH "${CMAKE_SYSTEM_PROCESSOR}")
endif()
if(TRANSLATE_TARGET_ARCH MATCHES "^(arm64|aarch64|armv7|arm)")
  add_compile_definitions(ARM FMA SSE)
  if(NOT MSVC)
    add_compile_options(-flax-vector-conversions -fno-strict-aliasing)
  endif()
endif()
# Marian was written for Windows with MSVC and spells three headers the
# way its file system does not mind: <Windows.h>, <WinBase.h> and
# <DbgHelp.h>. mingw-w64 ships them in lower case, and the Linux machine
# that cross-builds tells the two apart. One-line headers that pass on to
# the real ones, ahead of everything else on the include path.
if(MINGW)
  set(MINGW_COMPAT "${CMAKE_BINARY_DIR}/mingw-compat")
  file(WRITE "${MINGW_COMPAT}/Windows.h" "#include <windows.h>\n")
  file(WRITE "${MINGW_COMPAT}/WinBase.h" "#include <winbase.h>\n")
  file(WRITE "${MINGW_COMPAT}/DbgHelp.h" "#include <dbghelp.h>\n")
  include_directories(BEFORE SYSTEM "${MINGW_COMPAT}")
  # What Marian sets for itself under MSVC, and its Windows code assumes:
  # wide-character Win32 calls among them.
  add_compile_definitions(WIN32 _WINDOWS UNICODE _UNICODE
    _CRT_NONSTDC_NO_WARNINGS _CRT_SECURE_NO_WARNINGS)
  # And two things the MSVC and Linux headers bring in passing that GCC's
  # Windows headers do not: <cstdint> (faiss uses int64_t without it) and
  # bzero, which is POSIX.
  file(WRITE "${MINGW_COMPAT}/preppsuite_mingw.h"
    "#pragma once\n#include <cstdint>\n#include <cstring>\n#include <malloc.h>\n"
    "static inline void bzero(void* p, size_t n) { std::memset(p, 0, n); }\n")
  add_compile_options(
    "$<$<COMPILE_LANGUAGE:CXX>:SHELL:-include ${MINGW_COMPAT}/preppsuite_mingw.h>")
endif()
add_subdirectory("${BERGAMOT_SOURCE}" bergamot EXCLUDE_FROM_ALL)
if(MINGW)
  # PCRE2 is built here as a static library, but its header declares
  # every function as imported from a DLL unless told otherwise -- which
  # only the MSVC build of the sentence splitter remembered to do.
  target_compile_definitions(ssplit PUBLIC PCRE2_STATIC)
  # System libraries last on every link line, after the engine's static
  # archives that need them: DbgHelp for the call stacks Marian prints
  # with an exception, shlwapi for its path matching.
  set(CMAKE_CXX_STANDARD_LIBRARIES
    "${CMAKE_CXX_STANDARD_LIBRARIES} -ldbghelp -lshlwapi")
endif()

add_library(preppsuite_translate SHARED translate.cpp)
target_link_libraries(preppsuite_translate PRIVATE bergamot-translator-source)
set_target_properties(preppsuite_translate PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON)
# Only the C surface leaves the library. Hidden visibility covers what is
# compiled here, not the engine's static libraries linked in, so each
# linker is told the list itself.
if(APPLE)
  target_link_options(preppsuite_translate PRIVATE
    "-Wl,-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/translate.exports")
  set_target_properties(preppsuite_translate PROPERTIES
    INSTALL_NAME_DIR "@rpath")
endif()
# preppsuite_translate.dll, the name the app looks for, rather than the
# lib prefix mingw would give it.
if(WIN32)
  set_target_properties(preppsuite_translate PROPERTIES PREFIX "")
endif()
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Android")
  target_link_options(preppsuite_translate PRIVATE
    "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/translate.map")
endif()

add_executable(translate_selftest selftest.c)
target_link_libraries(translate_selftest PRIVATE preppsuite_translate)
