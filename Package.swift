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
        .package(url: "https://github.com/Quick/Quick.git", from: "7.6.2"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.8.0")
    ],
    targets: [
        .target(
            name: "TinyMeet",
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
