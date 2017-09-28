#
# Be sure to run `pod lib lint JCCardView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JCCardView'
  s.version          = '0.1.0'
  s.summary          = '一个带缓存的卡片视图实现，类似于探探，通过Masonry自动布局'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Fairtoys/JCCardView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '313574889@qq.com' => '313574889@qq.com' }
  s.source           = { :git => 'https://github.com/313574889@qq.com/JCCardView.git', :tag => s.version.to_s }
  s.social_media_url = 'http://www.jianshu.com/u/1668f8b922bc'

  s.ios.deployment_target = '8.0'

  s.source_files = 'JCCardView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JCCardView' => ['JCCardView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Masonry'
end
