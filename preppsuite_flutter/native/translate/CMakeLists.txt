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
add_subdirectory("${BERGAMOT_SOURCE}" bergamot EXCLUDE_FROM_ALL)

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
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL "Android")
  target_link_options(preppsuite_translate PRIVATE
    "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/translate.map")
endif()

add_executable(translate_selftest selftest.c)
target_link_libraries(translate_selftest PRIVATE preppsuite_translate)
