Pod::Spec.new do |s|
  s.name             = 'swifthelper'
  s.version          = '0.0.1'
  s.summary          = 'Helpers with many extensions to make it easy and speedup the development'
  s.homepage         = 'https://github.com/sansuba/swifthelper'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sansuba' => 'sanjsuba@gmail.com' }
  s.source           = { :git => 'https://github.com/sansuba/swifthelper.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Pod/Classes/**/*'
  s.frameworks = 'UIKit', 'Foundation'
end
