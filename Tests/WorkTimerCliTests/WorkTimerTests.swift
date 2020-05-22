import XCTest
import class Foundation.Bundle

final class WorkTimerTests: XCTestCase {
    func testBinary() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let workTimerBinary = productsDirectory.appendingPathComponent("work-timer")

        let process = Process()
        process.executableURL = workTimerBinary

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "not a terminal? Exiting...\n")
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
}
