Pod::Spec.new do |s|
    s.name             = 'ScreenProtectorKit'
    s.version          = '1.0.3'
    s.summary          = 'Safe Data Leakage via Application Background Screenshot and Prevent Screenshot for iOS.'
    s.homepage         = 'https://github.com/prongbang/ScreenProtectorKit'
    s.license          = 'MIT'
    s.author           = 'prongbang'
    s.source           = { :git => 'https://github.com/prongbang/ScreenProtectorKit.git', :tag => "#{s.version}" }
    s.social_media_url = 'https://github.com/prongbang'
    s.platform         = :ios, "12.0"
    s.swift_version    = "5.0"
    s.module_name      = "ScreenProtectorKit"
    s.source_files     = "Sources", "Sources/**/*.{h,m,swift}"
end
