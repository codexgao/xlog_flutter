cmake_minimum_required(VERSION 3.10)

project(xlog_flutter_library VERSION 0.0.1 LANGUAGES CXX)

# Mars xlog root (two levels up from samples/xlog_flutter/src/)
set(MARS_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../mars")

add_library(xlog_flutter SHARED
  "xlog_flutter.cpp"
)

target_include_directories(xlog_flutter PRIVATE
  "${MARS_ROOT}/xlog"
  "${MARS_ROOT}/xlog/export_include"
  "${MARS_ROOT}/comm"
)

set_target_properties(xlog_flutter PROPERTIES
  PUBLIC_HEADER xlog_flutter.h
  OUTPUT_NAME "xlog_flutter"
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
)

target_compile_definitions(xlog_flutter PUBLIC DART_SHARED_LIB)

# Platform-specific: link prebuilt xlog static library
if(WIN32)
  # Add Windows-specific sys/time.h path so <sys/time.h> resolves correctly
  target_include_directories(xlog_flutter PRIVATE "${MARS_ROOT}/comm/windows")

  set(XLOG_LIB_PATH "${MARS_ROOT}/cmake_build/Windows/Windows.out/win/mars.lib")
  if(EXISTS "${XLOG_LIB_PATH}")
    target_link_libraries(xlog_flutter PRIVATE "${XLOG_LIB_PATH}")
  else()
    message(WARNING "xlog prebuilt library not found at ${XLOG_LIB_PATH}. "
                    "Run: cd mars && python build_windows.py --xlog --config Release")
  endif()
elseif(ANDROID)
  file(GLOB_RECURSE XLOG_SOURCES
    "${MARS_ROOT}/xlog/src/*.cc"
    "${MARS_ROOT}/xlog/src/*.cpp"
    "${MARS_ROOT}/comm/*.cc"
    "${MARS_ROOT}/comm/*.cpp"
  )
  # Exclude platform-specific files that don't apply
  list(FILTER XLOG_SOURCES EXCLUDE REGEX ".*_test.*")
  list(FILTER XLOG_SOURCES EXCLUDE REGEX ".*/win/.*")
  list(FILTER XLOG_SOURCES EXCLUDE REGEX ".*/apple/.*")
  target_sources(xlog_flutter PRIVATE ${XLOG_SOURCES})
  target_link_libraries(xlog_flutter PRIVATE log z)
elseif(APPLE)
  # iOS/macOS: linking handled by podspec
elseif(UNIX)
  # Linux
  set(XLOG_LIB_PATH "${MARS_ROOT}/cmake_build/linux/libmars.a")
  if(EXISTS "${XLOG_LIB_PATH}")
    target_link_libraries(xlog_flutter PRIVATE "${XLOG_LIB_PATH}")
  else()
    message(WARNING "xlog prebuilt library not found at ${XLOG_LIB_PATH}.")
  endif()
endif()
