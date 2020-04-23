#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'window_utils_macos'
  s.version          = '1.0.3'
  s.summary          = 'Mac implementation of the windows_utils plugin.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://rive.app'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Rive Authors' => 'hello@rive.app' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end

