// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Raedam",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Raedam",
            targets: ["Raedam"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.29.0"),
        .package(url: "https://github.com/stripe/stripe-ios.git", from: "23.32.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.4"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.12.0"),
        .package(url: "https://github.com/malcommac/SwiftLocation.git", from: "5.1.0")
    ],
    targets: [
        .target(
            name: "Raedam",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SwiftLocation", package: "SwiftLocation")
            ],
            path: "Sources/Raedam")
    ]
)
