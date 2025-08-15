Pod::Spec.new do |s|
	s.name = 'LiveDigitalSDK'
	s.version = '2.11.15'
	s.summary = 'SDK for iOS to access LiveDigital media service'
	s.homepage = 'https://github.com/VLprojects/livedigital-ios-sdk-binary'
	s.license = { :type => 'MIT', :file => 'LICENSE' }
	s.author = { 'Alexander Gorbunov' => 'gorbunov.a@vlprojects.pro' }
	s.source = { :git => 'https://github.com/VLprojects/livedigital-ios-sdk-binary.git', :tag => s.version.to_s }
	s.ios.deployment_target = '15.0'
	s.swift_version = '5.4'

	s.dependency 'Mediasoup-Client-Swift', '0.8.0'

	s.vendored_frameworks =
		"LiveDigitalSDK.xcframework"

	s.frameworks =
		"AVFoundation",
		"AudioToolbox",
		"CoreAudio",
		"CoreMedia",
		"CoreVideo"
end
