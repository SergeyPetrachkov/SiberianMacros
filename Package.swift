// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SiberianMacros",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "SiberianMacros",
            targets: ["SiberianMacros"]
        ),
        .executable(
            name: "SiberianMacrosClient",
            targets: ["SiberianMacrosClient"]
        ),
    ],
    dependencies: [
        // Depend on the latest Swift 5.9 prerelease of SwiftSyntax
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "swift-5.9-DEVELOPMENT-SNAPSHOT-2023-07-06-a"),
    ],
    targets: [
        .macro(
            name: "MacrosImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: path(for: "MacrosImplementation")
        ),
        
        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "SiberianMacros",
            dependencies: ["MacrosImplementation"],
            path: path(for: "SiberianMacros")
        ),

        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(
            name: "SiberianMacrosClient",
            dependencies: ["SiberianMacros"],
            path: path(for: "SiberianMacrosClient")
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "SiberianMacrosTests",
            dependencies: [
                "MacrosImplementation",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)

// MARK: - Private helpers

func path(for target: String) -> String {
    "Sources/\(target)"
}
