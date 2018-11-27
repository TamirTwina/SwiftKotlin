// swift-tools-version:4.0


import PackageDescription

let package = Package(
  name: "SwiftKotlinFramework",
  products: [
    .library(
      name: "SwiftKotlinFramework",
      targets: [
        "SwiftKotlinFramework",
      ]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/yanagiba/swift-transform",
      .revision("45464c7747d97f320ca153b713affede11ce3bf4")
    )    
  ],
  targets: [
    .target(
      name: "SwiftKotlinFramework",
      dependencies: [
        "swift-transform",
      ],
      exclude: [
        "SwiftKotlin.xcworkspace"
      ]
    ),    

    // MARK: Tests
    .testTarget(
      name: "SwiftKotlinFrameworkTests",
      dependencies: [
        "SwiftKotlinFramework",
      ]
    ),    
  ],
  swiftLanguageVersions: [4]
)
