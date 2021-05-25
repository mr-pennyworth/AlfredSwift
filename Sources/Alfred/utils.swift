import Foundation

extension URL {
  static func /(parent: URL, child: String) -> URL {
    parent.appendingPathComponent(child)
  }
}

func log(
  _ message: String,
  filename: String = #file,
  function: String = #function,
  line: Int = #line
) {
  let basename = filename.split(separator: "/").last ?? ""
  NSLog("[\(basename):\(function):\(line)] \(message)")
}

func jsonObj(contentsOf filepath: URL) -> [String: Any]? {
  do {
    let data = try Data(contentsOf: filepath)
    let parsedJson = try JSONSerialization.jsonObject(with: data)
    if let json = parsedJson as? [String: Any] {
      return json
    }
  } catch {
    log("\(error)")
    log("Error: Couldn't read JSON object from: \(filepath.path)")
  }
  return nil
}
