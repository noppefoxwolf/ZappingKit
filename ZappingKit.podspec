#
# Be sure to run `pod lib lint ZappingKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ZappingKit'
  s.version          = '0.1.2'
  s.summary          = 'Provide zapping UI.'

  s.description      = <<-DESC
Provide zapping UI. Support navigation controllre life cycle.
                       DESC

  s.homepage         = 'https://github.com/noppefoxwolf/ZappingKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tomoya Hirano' => 'cromteria@gmail.com' }
  s.source           = { :git => 'https://github.com/noppefoxwolf/ZappingKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/noppefoxwolf'

  s.ios.deployment_target = '8.0'

  s.source_files = 'ZappingKit/Classes/**/*'
end
