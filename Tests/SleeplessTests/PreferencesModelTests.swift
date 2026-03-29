import XCTest
@testable import Sleepless

/// 偏好与枚举模型的单元测试（SwiftPM：`swift test`）
final class PreferencesModelTests: XCTestCase {
    func testDefaultDurationFromMinutesKnown() {
        XCTAssertEqual(DefaultDuration.from(minutes: 5), .fiveMin)
        XCTAssertEqual(DefaultDuration.from(minutes: 60), .oneHour)
        XCTAssertEqual(DefaultDuration.from(minutes: 0), .indefinite)
    }

    func testDefaultDurationFromMinutesUnknownFallsBackToIndefinite() {
        XCTAssertEqual(DefaultDuration.from(minutes: 999), .indefinite)
        XCTAssertEqual(DefaultDuration.from(minutes: -1), .indefinite)
    }

    func testMenuBarIconStyleSymbolTogglesWithActive() {
        let style = MenuBarIconStyle.moon
        XCTAssertEqual(style.symbol(active: false), style.symbolOff)
        XCTAssertEqual(style.symbol(active: true), style.symbolOn)
    }
}
