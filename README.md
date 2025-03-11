# PoliSDK

## 📌 요구 사항

- **iOS 버전**: 최소 iOS 12 이상
- **Xcode 버전**: Xcode 14 이상 권장
- **Swift 버전**: Swift 5 이상

## 🔧 설치 방법

### 1. CocoaPods 설정

HCBle을 설치하려면 먼저 CocoaPods이 필요합니다. 아래 명령어를 실행하여 CocoaPods을 설치하세요.

```bash
sudo gem install cocoapods
```

### 2. 프로젝트에 HCBle 추가

#### 1) GitHub 액세스 토큰 설정

먼저 GitHub 액세스 토큰을 설정해야 합니다. bashrc나 zshrc 파일에 유효한 토큰을 설정하세요

```bash
export GIT_ACCESS_TOKEN=ghp_qRZY..
```

#### 2) Podfile 설정

프로젝트의 `Podfile`을 열고 다음 내용을 추가하세요.

```ruby
source 'https://github.com/hconnectdx/ios-spec.git'

target 'YourAppTarget' do
  use_frameworks!
  pod 'PoliSDK', '~> 0.1.0'
end
```

#### 3) Pod 설치

아래 명령어를 실행하여 Pod을 설치합니다.

```bash
pod install
```
