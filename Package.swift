// swift-tools-version:5.8
import PackageDescription

let version = "2.11.1"
let checksum = "b175787dc1b7b6e946832223c3d59a21e88b5304e5f5c726ffacdbb69a6d4750"

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
