// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TinyMeet",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TinyMeet",
            targets: ["TinyMeet"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", exact: "7.6.2"),
        .package(url: "https://github.com/Quick/Nimble.git", exact: "13.8.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "12.12.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", exact: "8.0.0")
    ],
    targets: [
        .target(
            name: "TinyMeet",
            dependencies: [
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ],
            path: "TinyMeet"
        ),
        .testTarget(
            name: "TinyMeetTests",
            dependencies: [
                "TinyMeet",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble")
            ],
            path: "TinyMeetTests"
        )
    ]
)
