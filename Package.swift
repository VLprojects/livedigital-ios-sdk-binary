// swift-tools-version:5.8
import PackageDescription

let version = "2.12.0"
let checksum = "15e62e6a747b9d2c45689846059841c69acc06aa9bf019810dba80b3ceb5c494"

let package = Package(
	name: "LiveDigitalSDK",

	platforms: [
		.iOS(.v15)
	],

	products: [
		.library(
			name: "LiveDigitalSDK",
			targets: ["LiveDigitalSDKWrapper"]
		)
	],

	dependencies: [
		.package(
			url: "https://github.com/VLprojects/mediasoup-client-swift.git",
			exact: "0.8.0"
		)
	],

	targets: [
		.target(
			name: "LiveDigitalSDKWrapper",
			dependencies: [
				.product(name: "Mediasoup", package: "Mediasoup-Client-Swift"),
				.target(name: "LiveDigitalSDK"),
			],
			path: "Sources/LiveDigitalSDKWrapper",
			publicHeadersPath: ""
		),

		.binaryTarget(
			name: "LiveDigitalSDK",
			url: "https://github.com/VLprojects/livedigital-ios-sdk-binary/releases/download/\(version)/LiveDigitalSDK.xcframework.zip",
			checksum: checksum
		),
	]
)
