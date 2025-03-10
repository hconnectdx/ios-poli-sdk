Pod::Spec.new do |s|
  # 변수 설정
  token = ENV['GIT_ACCESS_TOKEN']
  name = 'PoliSDK'
  version = '0.1.0'
  description = 'This is a ios PoliSDK'
  repo_url = 'https://github.com/hconnectdx/ios-bt-sdk'
  
  s.name             = name
  s.version          = version
  s.summary          = description

  s.description      = description
  s.homepage         = repo_url
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'x-oauth-basic' => 'kmwdev@hconnect.co.kr' }
  s.source           = { :git => "https://oauth2:#{token}@github.com/hconnectdx/bt-sdk-ios.git", :tag => version }
  
  # s.screenshots    = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'PoliSDK/Classes/**/*', 'Classes/**/*.swift'
  s.dependency 'HCBle', '~> 0.1.3'

end
