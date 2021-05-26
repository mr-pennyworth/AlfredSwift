import Foundation

public class Plist {
  private var dict: [String: Any] = [String: Any]()

  public init(path: URL) {
    if let plist = NSDictionary(contentsOf: path) as? [String: Any] {
      dict = plist
    } else {
      log("Error: Could not parse '\(path.path)' as a dict.")
    }
  }

  public func get<T>(_ key: String) -> T? {
    if let value = dict[key] as? T {
      return value
    } else {
      return nil
    }
  }

  public func get<T>(_ key: String, orElse: T) -> T {
    if let value = dict[key] as? T {
      return value
    } else {
      return orElse
    }
  }
}
