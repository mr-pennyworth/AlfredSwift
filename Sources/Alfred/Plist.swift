import Foundation

class Plist {
  private var dict: [String: Any] = [String: Any]()

  init(path: URL) {
    if let plist = NSDictionary(contentsOf: path) as? [String: Any] {
      dict = plist
    } else {
      log("Error: Could not parse '\(path.path)' as a dict.")
    }
  }

  func get<T>(_ key: String) -> T? {
    if let value = dict[key] as? T {
      return value
    } else {
      return nil
    }
  }

  func get<T>(_ key: String, orElse: T) -> T {
    if let value = dict[key] as? T {
      return value
    } else {
      return orElse
    }
  }
}
