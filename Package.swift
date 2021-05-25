// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "AlfredSwift",
  platforms: [
    .macOS(.v10_14),
  ],
  products: [
    .library(
      name: "Alfred",
      targets: ["Alfred"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "Alfred",
      dependencies: []),
    .testTarget(
      name: "AlfredTests",
      dependencies: ["Alfred"]),
  ]
)
