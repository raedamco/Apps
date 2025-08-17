// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ParkingApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ParkingApp",
            targets: ["ParkingApp"]),
    ],
    dependencies: [
        // Firebase for authentication and backend services
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        
        // Stripe for payment processing
        .package(url: "https://github.com/stripe/stripe-ios.git", from: "23.0.0"),
        
        // MapKit integration helpers
        .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "10.0.0"),
        
        // Networking and JSON parsing
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        
        // Swift concurrency utilities
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "0.1.0"),
        
        // UI components and utilities
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        
        // Localization and internationalization
        .package(url: "https://github.com/malcommac/SwiftLocation.git", from: "5.0.0"),
        
        // Bluetooth connectivity
        .package(url: "https://github.com/Polidea/RxBluetoothKit.git", from: "6.0.0"),
        
        // Push notifications
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "ParkingApp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "MapboxMaps", package: "mapbox-maps-ios"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "SwiftLocation", package: "SwiftLocation"),
                .product(name: "RxBluetoothKit", package: "RxBluetoothKit")
            ]),
        .testTarget(
            name: "ParkingAppTests",
            dependencies: ["ParkingApp"]),
    ]
)
