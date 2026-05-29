// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FreezeTextMCP",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FreezeTextMCP", targets: ["FreezeTextMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0")
    ],
    targets: [
        .executableTarget(
            name: "FreezeTextMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ],
            path: "Sources/FreezeTextMCP"
        )
    ]
)
