import XCTest
@testable import swiftETH

final class BalanceConversionTests: XCTestCase {
    func testBalanceConversion_0_0001_ETH() throws {
        let balance = try Balance(hex: "0x5af3107a4000")
        let eth = balance.toEther()
        
        XCTAssertEqual(eth, 0.0001, accuracy: 0.0000001, "0x5af3107a4000 should equal 0.0001 ETH")
    }
    
    func testBalanceConversion_1_ETH() throws {
        let balance = try Balance(hex: "0xde0b6b3a7640000")
        let eth = balance.toEther()
        
        XCTAssertEqual(eth, 1.0, accuracy: 0.0000001, "0xde0b6b3a7640000 should equal 1 ETH")
    }
    
    func testBalanceFormatting() throws {
        let balance = try Balance(hex: "0x5af3107a4000")
        let formatted = balance.formatted(decimals: 6)
        
        XCTAssertTrue(formatted.contains("0.0001"), "Should format as 0.0001 ETH")
    }
}
