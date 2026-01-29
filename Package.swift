// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "imandefterim",
    platforms: [.iOS(.v17)],
    products: [],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
        .package(url: "https://github.com/google/google-mobile-ads-sdk-ios.git", from: "11.0.0"),
    ],
    targets: []
)
