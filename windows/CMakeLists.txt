# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "xlog_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

# Shared source lives in ../src/ (no separate CMakeLists.txt needed there).
# Resolve real path so symlink traversal (Flutter .plugin_symlinks/) works correctly.
get_filename_component(PLUGIN_WIN_REAL "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)
set(PLUGIN_SRC  "${PLUGIN_WIN_REAL}/../src")
set(INCLUDE_DIR "${PLUGIN_WIN_REAL}/../include")
set(LIB_DIR     "${PLUGIN_WIN_REAL}/libs")

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
# Match the CRT of the prebuilt xlog.lib to avoid LNK2038 mismatches.
# The prebuilt Release lib uses /MT (MultiThreaded static CRT).
# If a debug-specific lib exists at libs/x64/debug/xlog.lib (built
# with --config Debug), it uses /MDd and the target switches to MDd as well.
set(XLOG_LIB_DEBUG   "${LIB_DIR}/x64/debug/xlog.lib")
set(XLOG_LIB_RELEASE "${LIB_DIR}/x64/xlog.lib")

# OpenSSL prebuilt libs (required by comm thread cleanup: OPENSSL_thread_stop)
set(OPENSSL_CRYPTO_LIB "${LIB_DIR}/x64/openssl/libcrypto.lib")
set(OPENSSL_SSL_LIB    "${LIB_DIR}/x64/openssl/libssl.lib")

# zstd prebuilt libs (required by log_zstd_buffer in xlog)
set(ZSTD_LIB_DEBUG   "${LIB_DIR}/x64/debug/zstd_static.lib")
set(ZSTD_LIB_RELEASE "${LIB_DIR}/x64/zstd_static.lib")

if(EXISTS "${XLOG_LIB_DEBUG}")
  # Debug lib 以 /MDd (MultiThreadedDebugDLL) 编译，与 Flutter plugin 的默认 CRT 一致
  # Release lib 以 /MT (MultiThreaded) 编译（mars 默认静态 CRT）
  # 注意：如需重新构建 debug lib，必须加 -DMARS_USE_DYNAMIC_CRT=ON：
  #   cd mars && python build_windows.py --xlog --config Debug
  #   然后复制 cmake_build/Windows/Windows.out/win/xlog.lib 到 windows/libs/x64/debug/xlog.lib
  set_property(TARGET xlog_flutter PROPERTY
    MSVC_RUNTIME_LIBRARY
      "$<$<CONFIG:Debug>:MultiThreadedDebugDLL>$<$<NOT:$<CONFIG:Debug>>:MultiThreaded>")
  target_link_libraries(xlog_flutter PRIVATE
    "$<$<CONFIG:Debug>:${XLOG_LIB_DEBUG}>$<$<NOT:$<CONFIG:Debug>>:${XLOG_LIB_RELEASE}>"
    "$<$<CONFIG:Debug>:${ZSTD_LIB_DEBUG}>$<$<NOT:$<CONFIG:Debug>>:${ZSTD_LIB_RELEASE}>"
    "${OPENSSL_CRYPTO_LIB}" "${OPENSSL_SSL_LIB}"
    ws2_32 crypt32)
elseif(EXISTS "${XLOG_LIB_RELEASE}")
  # 只有 Release lib：强制使用 /MT，与预编译静态库的 CRT 保持一致
  set_property(TARGET xlog_flutter PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded")
  target_link_libraries(xlog_flutter PRIVATE
    "${XLOG_LIB_RELEASE}"
    "${ZSTD_LIB_RELEASE}"
    "${OPENSSL_CRYPTO_LIB}" "${OPENSSL_SSL_LIB}"
    ws2_32 crypt32)
else()
  message(WARNING
    "xlog prebuilt lib not found.\n"
    "构建 Release lib: cd mars && python build_windows.py --xlog --config Release\n"
    "  然后复制 cmake_build/Windows/Windows.out/win/xlog.lib 到 windows/libs/x64/xlog.lib\n"
    "构建 Debug lib:   cd mars && python build_windows.py --xlog --config Debug\n"
    "  然后复制 cmake_build/Windows/Windows.out/win/xlog.lib 到 windows/libs/x64/debug/xlog.lib")
endif()

# List of absolute paths to libraries that should be bundled with the plugin.
set(xlog_flutter_bundled_libraries
  $<TARGET_FILE:xlog_flutter>
  PARENT_SCOPE
)
