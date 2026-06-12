import XCTest
@testable import SwiftPipeGiga

final class BootstrapTests: XCTestCase {
    func testPackageIsWired() {
        XCTAssertTrue(SwiftPipeGiga.bootstrap)
    }
}
