// swift-tools-version:5.8
import PackageDescription

let version = "3.0.1"
let checksum = "493e856f3189f0b25e20783dea1bb207f14a51da1cfc90dd65097d9a836f547b"

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
			exact: "0.11.0"
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
