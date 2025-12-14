Pod::Spec.new do |s|
    s.name             = 'ScreenProtectorKit'
    s.version          = '1.5.0'
    s.summary          = 'Safe Data Leakage via Application Background Screenshot and Prevent Screenshot for iOS.'
    s.homepage         = 'https://github.com/prongbang/ScreenProtectorKit'
    s.license          = 'MIT'
    s.author           = 'prongbang'
    s.source           = { :git => 'https://github.com/prongbang/ScreenProtectorKit.git', :tag => "#{s.version}" }
    s.social_media_url = 'https://github.com/prongbang'
    s.platform         = :ios, "12.0"
    s.swift_versions   = ["4.0", "4.1", "4.2", "5.0", "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8", "5.9", "6.0"]
    s.module_name      = "ScreenProtectorKit"
    s.source_files     = "Sources", "Sources/**/*.{h,m,swift}"
    s.vendored_frameworks = "Frameworks/ScreenPreventerKit.xcframework"
end
