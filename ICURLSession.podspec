#
# Be sure to run `pod lib lint ICURLSession.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ICURLSession'
  s.version          = '0.9.0'
  s.summary          = 'A block wrap for NSURLSession.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Just a block wrap for NSURLSession.
                       DESC

  s.homepage         = 'https://github.com/IvanChan/ICURLSession'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '_ivanC' => '_ivanC'}
  s.source           = { :git => 'https://github.com/IvanChan/ICURLSession.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  
  s.source_files = 'ICURLSession/Classes/**/*'
  s.public_header_files = 'ICURLSession/Classes/ICURLSession.h'

  # s.resource_bundles = {
  #   'ICURLSession' => ['ICURLSession/Assets/*.png']
  # }

  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
