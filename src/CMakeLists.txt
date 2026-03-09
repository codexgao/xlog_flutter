cmake_minimum_required(VERSION 3.10)

project(xlog_flutter_library VERSION 0.0.1 LANGUAGES CXX)

# Resolve real path so symlink traversal (Flutter .plugin_symlinks/) works correctly.
get_filename_component(PLUGIN_SRC_REAL "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)
set(PLUGIN_ROOT "${PLUGIN_SRC_REAL}/..")

# Headers and prebuilt libs bundled with the plugin (self-contained, no mars source tree needed)
set(INCLUDE_DIR "${PLUGIN_ROOT}/include")
set(LIB_DIR     "${PLUGIN_ROOT}/libs")

add_library(xlog_flutter SHARED
  "xlog_flutter.cpp"
)

target_include_directories(xlog_flutter PRIVATE "${INCLUDE_DIR}")

set_target_properties(xlog_flutter PROPERTIES
  PUBLIC_HEADER xlog_flutter.h
  OUTPUT_NAME "xlog_flutter"
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
)

target_compile_definitions(xlog_flutter PUBLIC DART_SHARED_LIB)

# ---------------------------------------------------------------------------
# Platform-specific: link prebuilt xlog static library
# ---------------------------------------------------------------------------
if(WIN32)
  # include/sys/time.h provides gettimeofday() compatibility on Windows
  set(XLOG_LIB "${LIB_DIR}/windows/x64/mars.lib")
  if(EXISTS "${XLOG_LIB}")
    target_link_libraries(xlog_flutter PRIVATE "${XLOG_LIB}")
  else()
    message(WARNING
      "xlog prebuilt lib not found: ${XLOG_LIB}\n"
      "Build it with: cd mars && python build_windows.py --xlog --config Release\n"
      "Then copy the output to libs/windows/x64/mars.lib")
  endif()

elseif(ANDROID)
  set(XLOG_LIB "${LIB_DIR}/android/${ANDROID_ABI}/libmarsxlog.a")
  if(EXISTS "${XLOG_LIB}")
    target_link_libraries(xlog_flutter PRIVATE "${XLOG_LIB}" log z)
  else()
    message(WARNING
      "xlog prebuilt lib not found: ${XLOG_LIB}\n"
      "Build it with: cd mars && python build_android.py\n"
      "Then copy each ABI .a to libs/android/<ABI>/libmarsxlog.a")
  endif()

elseif(APPLE)
  # iOS/macOS: linking handled by the podspec via vendored_frameworks

elseif(UNIX)
  set(XLOG_LIB "${LIB_DIR}/linux/x64/libmars.a")
  if(EXISTS "${XLOG_LIB}")
    target_link_libraries(xlog_flutter PRIVATE "${XLOG_LIB}")
  else()
    message(WARNING
      "xlog prebuilt lib not found: ${XLOG_LIB}\n"
      "Build it with: cd mars && mkdir -p cmake_build/linux && cd cmake_build/linux && cmake ../.. && cmake --build . --target marsxlog\n"
      "Then copy to libs/linux/x64/libmars.a")
  endif()

endif()
