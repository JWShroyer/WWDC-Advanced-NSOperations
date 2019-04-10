#
#  Be sure to run `pod spec lint TMOperations.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name           = 'TMOperations'
  s.version        = '1.0.0'
  s.summary        = "An updated version of Apple's Operations example from their 2016 WWDC Advanced Operations presentation."
  s.homepage       = 'https://github.com/LondonAtlas/WWDC-Advanced-NSOperations'
  s.license        = { :type => 'MIT' }
  s.author         = { 'Tom Marks' => '', 'Joshua Shroyer' => '' }
  s.source         = { :git => "https://github.com/LondonAtlas/WWDC-Advanced-NSOperations.git", :tag => "#{s.version}" }
  s.preserve_paths = '*'
  s.exclude_files  = '**/file.zip'
end

