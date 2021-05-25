import Foundation

extension URL {
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

extension FileManager {
  func exists(_ url: URL) -> Bool {
    fileExists(atPath: url.path)
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
