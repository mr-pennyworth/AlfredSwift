// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "AlfredSwift",
  platforms: [
    .macOS(.v11),
  ],
  products: [
    .library(
      name: "Alfred",
      targets: ["Alfred"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/NozeIO/MicroExpress",
      .upToNextMinor(from: "0.5.3")),
  ],
  targets: [
    .target(
      name: "Alfred",
      dependencies: ["MicroExpress"]),
    .testTarget(
      name: "AlfredTests",
      dependencies: ["Alfred"]),
  ]
)
