import XCTest
@testable import swiftETH

final class BalanceTests: XCTestCase {
    func testBalanceFromHex() throws {
        let balance = try Balance(hex: "0x1bc16d674ec80000")
        XCTAssertEqual(balance.raw, "0x1bc16d674ec80000")
        XCTAssertFalse(balance.isZero)
    }
    
    func testZeroBalance() throws {
        let balance = try Balance(hex: "0x0")
        XCTAssertTrue(balance.isZero)
        XCTAssertEqual(balance.formatted(), "0 ETH")
    }
    
    func testBalanceFormatting() throws {
        let balance = try Balance(hex: "0x1bc16d674ec80000")
        let formatted = balance.formatted()
        XCTAssertTrue(formatted.contains("ETH"))
    }
    
    func testBalanceFromWeiString() {
        let balance = Balance(wei: "1000000000000000000")
        XCTAssertEqual(balance.raw, "0x1000000000000000000")
    }
}
