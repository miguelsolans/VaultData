// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VaultData",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VaultData",
            targets: ["VaultData"]
        ),
    ],
    dependencies: [
        .package(path: "../../VaultDomain/VaultDomain")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "VaultData",
            dependencies: [
                .product(
                    name: "VaultDomain",
                    package: "VaultDomain"
                )
            ],
            resources: [
                .process("Model/VaultModel.xcdatamodeld")
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
