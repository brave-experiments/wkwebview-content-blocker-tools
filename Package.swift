// swift-tools-version: 5.7
import PackageDescription

let package = Package(
  name: "WebKit Tools",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "webkit-tools", targets: ["WebKitTools"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
  ],
  targets: [
    .executableTarget(
      name: "WebKitTools",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ]
    ),
    .testTarget(
      name: "WebKitToolsTests",
      dependencies: ["WebKitTools"]),
  ]
)
