import XCTest
import AVFoundation
@testable import SwiftPipePlayer

final class BootstrapTests: XCTestCase {
    func testAVFoundationLinksAndPlayerInitializes() {
        XCTAssertTrue(SwiftPipePlayer.bootstrap)
        let player = AVPlayer()
        XCTAssertEqual(player.rate, 0)
    }
}
