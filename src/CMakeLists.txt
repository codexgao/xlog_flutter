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
  # Match the CRT of the prebuilt xlog.lib to avoid LNK2038 mismatches.
  # The prebuilt Release lib uses /MT (MultiThreaded static CRT).
  # If a debug-specific lib exists at libs/windows/x64/debug/xlog.lib (built
  # with --config Debug), it uses /MDd and the target switches to MDd as well.
  set(XLOG_LIB_DEBUG   "${LIB_DIR}/windows/x64/debug/xlog.lib")
  set(XLOG_LIB_RELEASE "${LIB_DIR}/windows/x64/xlog.lib")

  # OpenSSL prebuilt libs (required by comm thread cleanup: OPENSSL_thread_stop)
  set(OPENSSL_CRYPTO_LIB "${LIB_DIR}/windows/x64/openssl/libcrypto.lib")
  set(OPENSSL_SSL_LIB    "${LIB_DIR}/windows/x64/openssl/libssl.lib")

  # zstd prebuilt libs (required by log_zstd_buffer in xlog)
  set(ZSTD_LIB_DEBUG   "${LIB_DIR}/windows/x64/debug/zstd_static.lib")
  set(ZSTD_LIB_RELEASE "${LIB_DIR}/windows/x64/zstd_static.lib")

  if(EXISTS "${XLOG_LIB_DEBUG}")
    # Debug lib 以 /MDd (MultiThreadedDebugDLL) 编译，与 Flutter plugin 的默认 CRT 一致
    # Release lib 以 /MT (MultiThreaded) 编译（mars 默认静态 CRT）
    # 注意：如需重新构建 debug lib，必须加 -DMARS_USE_DYNAMIC_CRT=ON：
    #   cd mars && python build_windows.py --xlog --config Debug
    #   然后复制 cmake_build/Windows/Windows.out/win/xlog.lib 到 libs/windows/x64/debug/xlog.lib
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
      "  然后复制 cmake_build/Windows/Windows.out/win/xlog.lib 到 libs/windows/x64/xlog.lib\n"
      "构建 Debug lib:   cd mars && python build_windows.py --xlog --config Debug\n"
      "  然后复制 cmake_build/Windows/Windows.out/win/xlog.lib 到 libs/windows/x64/debug/xlog.lib")
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
  set(XLOG_LIB "${LIB_DIR}/linux/x64/libxlog.a")
  if(EXISTS "${XLOG_LIB}")
    target_link_libraries(xlog_flutter PRIVATE "${XLOG_LIB}")
  else()
    message(WARNING
      "xlog prebuilt lib not found: ${XLOG_LIB}\n"
      "Build it with: cd mars && mkdir -p cmake_build/linux && cd cmake_build/linux && cmake ../.. && cmake --build . --target xlog\n"
      "Then copy cmake_build/linux/xlog/libxlog.a to libs/linux/x64/libxlog.a")
  endif()

endif()
