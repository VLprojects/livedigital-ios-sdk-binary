// swift-tools-version:5.8
import PackageDescription

let version = "3.6.0"
let checksum = "a84583ccc272c6c5003fc27457e2a5dddabe7175d18cba1cde600d9583b240e2"

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
			exact: "0.13.0"
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
