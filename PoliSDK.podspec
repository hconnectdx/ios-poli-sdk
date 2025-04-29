Pod::Spec.new do |s|
  # 변수 설정
  token = ENV['GIT_ACCESS_TOKEN']
  name = 'PoliSDK'
  version = '1.0.2'
  description = 'This is a ios PoliSDK'
  repo_url = 'https://github.com/hconnectdx/ios-poli-sdk'
  
  s.name             = name
  s.version          = version
  s.summary          = description

  s.description      = description
  s.homepage         = repo_url
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'x-oauth-basic' => 'kmwdev@hconnect.co.kr' }
  s.source           = { :git => "https://oauth2:#{token}@github.com/hconnectdx/ios-poli-sdk.git", :tag => version }
  
  # s.screenshots    = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'PoliSDK/PoliClasses/**/*'
  s.dependency 'HCBle', '~> 0.1.9'

end

# 배포 명령어
# pod repo push hconnectdx-ios-spec PoliSDK.podspec --sources='https://github.com/hconnectdx/ios-spec.git' --allow-warnings
