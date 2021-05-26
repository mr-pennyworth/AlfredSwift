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

  func testJsonFlatten() {
    XCTAssertEqual(
      flattenJsonObj(
        arraylessJsonObj: ["a": [ "b": ["c": ["d": 42]]]],
        keySeparator: "-"
      ) as NSObject,
      ["a-b-c-d": 42] as NSObject
    )

    XCTAssertEqual(
      flattenJsonObj(
        arraylessJsonObj: [
          "a": [
            "b": 1,
            "c": "Alfred"
          ],
          "d": 4.2
        ],
        keySeparator: "."
      ) as NSObject,
      [
        "a.b": 1,
        "a.c": "Alfred",
        "d": 4.2
      ] as NSObject
    )

    // Arrays should be simply ignored
    XCTAssertEqual(
      flattenJsonObj(
        arraylessJsonObj: [
          "a": [
            "b": 1,
            "c": "Alfred",
            "e": ["Pennyworth", 42]
          ],
          "d": 4.2
        ],
        keySeparator: "."
      ) as NSObject,
      [
        "a.b": 1,
        "a.c": "Alfred",
        "d": 4.2
      ] as NSObject
    )

    XCTAssertEqual(
      flattenJsonObj(
        arraylessJsonObj: [String: Any]()
      ) as NSObject,
      [String: Any]() as NSObject
    )
  }

  static var allTests = [
    ("testAlfred", testAlfred),
    ("testAlfredThemeDetector", testAlfredThemeDetector),
    ("testDarkModeDetector", testDarkModeDetector),
    ("testJsonFlatten", testJsonFlatten),
  ]
}
