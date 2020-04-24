
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
    s.name             = 'window_utils'
    s.version          = '1.0.3'
    s.summary          = 'No-op implementation of the macos window_utils to avoid build issues on macos'
    s.description      = <<-DESC
    No-op implementation of the window_utils plugin to avoid build issues on macos.
    https://github.com/flutter/flutter/issues/46618
                         DESC
    s.homepage         = 'https://github.com/rive-app/rive'
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'Rive Team' => 'hello@rive.app' }
    s.source           = { :path => '.' }
    s.source_files = 'Classes/**/*'
    s.public_header_files = 'Classes/**/*.h'
  
    s.platform = :osx
    s.osx.deployment_target = '10.11'
  end