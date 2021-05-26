import XCTest
@testable import Alfred

final class AlfredTests: XCTestCase {
  func testAlfred() {
    XCTAssertEqual(Alfred.isInstalled, true)
    XCTAssertEqual(Alfred.version > Semver("4.0.0"), true)
    XCTAssertEqual(Alfred.version < Semver("5.0.0"), true)
    XCTAssertEqual(Alfred.hasPressSecretary, true)
    XCTAssertEqual(
      Alfred.prefsDir.pathComponents.last!,
      "Alfred.alfredpreferences"
    )
  }

  func testAlfredThemeDetector() {
    XCTAssertEqual(Alfred.themeID.split(separator: ".")[0], "theme")
  }

  func testDarkModeDetector() {
    XCTAssertEqual(MacTheme(), .Dark)
  }

  static var allTests = [
    ("testAlfred", testAlfred),
    ("testAlfredThemeDetector", testAlfredThemeDetector),
    ("testDarkModeDetector", testDarkModeDetector),
  ]
}
