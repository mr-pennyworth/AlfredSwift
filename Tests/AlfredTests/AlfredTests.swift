import XCTest
@testable import Alfred
// comment the @testable line above and
// uncomment the line below for ad-hoc visibility testing
// import Alfred

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

  static let scriptFilterResponse: ScriptFilterResponse = {
    var resp = ScriptFilterResponse()
    let foobar = URL(fileURLWithPath: "/tmp/foobar")
    resp.items.append(.item(
      arg: "arg",
      title: "title",
      quicklookurl: URL(string: "http://google.com"),
      type: .fileSkipCheck,
      icon: .forFileType(uti: "public.folder"),
      mods: .mods(
        cmd: .mod(
          icon: .ofFile(at: foobar)
        ),
        alt: .mod(
          valid: true,
          icon: .fromImage(at: foobar)
        )
      )
    ))
    return resp
  }()

  func testScriptFilterResponse() {
    let producedJson =
      AlfredTests.scriptFilterResponse.asJsonStr(sortKeys: true)

    let expectedJson =
      """
      {
        "items" : [
          {
            "arg" : "arg",
            "icon" : {
              "path" : "public.folder",
              "type" : "filetype"
            },
            "mods" : {
              "alt" : {
                "icon" : {
                  "path" : "/tmp/foobar"
                },
                "valid" : true
              },
              "cmd" : {
                "icon" : {
                  "path" : "/tmp/foobar",
                  "type" : "fileicon"
                }
              }
            },
            "quicklookurl" : "http://google.com",
            "title" : "title",
            "type" : "file:skipcheck"
          }
        ]
      }
      """
    XCTAssertEqual(producedJson, expectedJson)
  }

  func testScriptFilterServer() {
    class Handler: ScriptFilter {
      func respond(to query: [String: String]) -> ScriptFilterResponse {
        AlfredTests.scriptFilterResponse
      }
    }

    let port = 9933
    let server = ScriptFilterServer(port: port, handler: Handler())
    server.start()

    let respData = fetch("http://localhost:\(port)")
    let received = try! JSONDecoder().decode(
      ScriptFilterResponse.self,
      from: respData
    )
    XCTAssertEqual(
      AlfredTests.scriptFilterResponse.asJsonStr(),
      received.asJsonStr()
    )
  }

  static var allTests = [
    ("testAlfred", testAlfred),
    ("testAlfredThemeDetector", testAlfredThemeDetector),
    ("testDarkModeDetector", testDarkModeDetector),
    ("testJsonFlatten", testJsonFlatten),
    ("testScriptFilterResponse", testScriptFilterResponse),
  ]
}

func fetch(_ url: String) -> Data {
  var req = URLRequest(url: URL(string: url)!)
  req.httpMethod = "GET"

  let (data, _, _) = URLSession.shared.syncRequest(with: req)
  return data!
}

// https://stackoverflow.com/a/67347651
extension URLSession {
  func syncRequest(with url: URL) -> (Data?, URLResponse?, Error?) {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    let dispatchGroup = DispatchGroup()
    let task = dataTask(with: url) {
      data = $0
      response = $1
      error = $2
      dispatchGroup.leave()
    }
    dispatchGroup.enter()
    task.resume()
    dispatchGroup.wait()

    return (data, response, error)
  }

  func syncRequest(with request: URLRequest) -> (Data?, URLResponse?, Error?) {
    var data: Data?
    var response: URLResponse?
    var error: Error?

    let dispatchGroup = DispatchGroup()
    let task = dataTask(with: request) {
      data = $0
      response = $1
      error = $2
      dispatchGroup.leave()
    }
    dispatchGroup.enter()
    task.resume()
    dispatchGroup.wait()

    return (data, response, error)
  }
}
