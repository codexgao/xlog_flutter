#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint xlog_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'xlog_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter FFI plugin wrapping the mars xlog logging library.'
  s.description      = 'Provides Flutter apps with high-performance, reliable logging via WeChat Mars xlog.'
  s.homepage         = 'https://github.com/Tencent/mars'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Tencent' => 'mars@tencent.com' }

  # Mars root relative to this podspec
  mars_root = File.join(__dir__, '..', '..', '..', 'mars')

  # Include the xlog wrapper from src/
  s.source           = { :path => '.' }
  s.source_files = [
    'Classes/**/*',
    "../src/xlog_flutter.cpp",
    "../src/xlog_flutter.h",
  ]

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'                        => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]'  => 'i386',
    'HEADER_SEARCH_PATHS'                   => [
      File.join(mars_root, 'xlog'),
      File.join(mars_root, 'xlog', 'export_include'),
      File.join(mars_root, 'comm'),
    ].join(' '),
    'CLANG_CXX_LANGUAGE_STANDARD'          => 'c++17',
  }

  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'
end
