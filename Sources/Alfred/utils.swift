import Foundation

public extension URL {
  static func /(parent: URL, child: String) -> URL {
    parent.appendingPathComponent(child)
  }

  func subDirs() -> [URL] {
    let fs = FileManager.default
    guard hasDirectoryPath else {
      log("Error: couldn't get contents of directory: \(path)")
      return []
    }
    if let dirs = try? fs.contentsOfDirectory(
      at: self,
      includingPropertiesForKeys: nil
    ).filter(\.hasDirectoryPath) {
      return dirs
    } else {
      log("Error: couldn't get contents of directory: \(path)")
      return []
    }
  }
}

public extension FileManager {
  func exists(_ url: URL) -> Bool {
    fileExists(atPath: url.path)
  }
}

public func log(
  _ message: String,
  filename: String = #file,
  function: String = #function,
  line: Int = #line
) {
  let basename = filename.split(separator: "/").last ?? ""
  NSLog("[\(basename):\(line) \(function)] \(message)")
}

public func jsonObj(contentsOf filepath: URL) -> [String: Any]? {
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

/// Flatten a JSON object (ignoring any arrays)
///
/// ```
/// Example input:
/// {
///   "a": {
///     "b": 9,
///     "c": "hello
///   },
///   "d": 4.2,
/// }
///
/// Example output:
/// {
///   "a-b": 9,
///   "a-c": "hello,
///   "d": 4.2
/// }
/// ```
/// - Parameters:
///   - arraylessJsonObj: JSON object that's known to not have arrays
///   - keySeparator: string that joins keys at various levels
/// - Returns: a single-level JSON object
func flattenJsonObj(
  arraylessJsonObj: [String: Any],
  keySeparator: String = "-"
) -> [String: Any] {
  var flattened = [String: Any]()
  for (key, value) in arraylessJsonObj {
    switch value {
    case let obj as [String: Any]:
      let flatObj = flattenJsonObj(
        arraylessJsonObj: obj,
        keySeparator: keySeparator
      )
      for (innerKey, value) in flatObj {
        flattened[key + keySeparator + innerKey] = value
      }
    case let arr as [Any]:
      log("Error: encountered \(arr) while flattening JSON.")
    default:
      flattened[key] = value
    }
  }
  return flattened
}
