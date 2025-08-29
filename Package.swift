// swift-tools-version:5.8
import PackageDescription

let version = "2.12.1"
let checksum = "d3592c0bf635b93521806b0451c8b295de2dd5d4fd4ab1676c92ae6b3c958424"

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
