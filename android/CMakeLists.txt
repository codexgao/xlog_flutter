cmake_minimum_required(VERSION 3.10)

project(xlog_flutter_library VERSION 0.0.1 LANGUAGES CXX)

# Resolve real path so symlink traversal (Flutter .plugin_symlinks/) works correctly.
get_filename_component(PLUGIN_ANDROID_REAL "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)
set(PLUGIN_SRC  "${PLUGIN_ANDROID_REAL}/../src")
set(INCLUDE_DIR "${PLUGIN_ANDROID_REAL}/../include")
set(LIB_DIR     "${PLUGIN_ANDROID_REAL}/libs")

add_library(xlog_flutter SHARED
  "${PLUGIN_SRC}/xlog_flutter.cpp"
)

target_include_directories(xlog_flutter PRIVATE "${INCLUDE_DIR}" "${PLUGIN_SRC}")

set_target_properties(xlog_flutter PROPERTIES
  PUBLIC_HEADER "${PLUGIN_SRC}/xlog_flutter.h"
  OUTPUT_NAME "xlog_flutter"
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
)

target_compile_definitions(xlog_flutter PUBLIC DART_SHARED_LIB)

# ---------------------------------------------------------------------------
# Link prebuilt xlog static library
# ---------------------------------------------------------------------------
set(XLOG_LIB "${LIB_DIR}/${ANDROID_ABI}/libmarsxlog.a")
if(EXISTS "${XLOG_LIB}")
  target_link_libraries(xlog_flutter PRIVATE "${XLOG_LIB}" log z)
else()
  message(WARNING
    "xlog prebuilt lib not found: ${XLOG_LIB}\n"
    "Build it with: cd mars && python build_android.py\n"
    "Then copy each ABI .a to android/libs/<ABI>/libmarsxlog.a")
endif()
