import Foundation

/// [Detect Dark mode on macOS][1]
/// [1]: https://stackoverflow.com/a/25652260
public enum MacTheme: String {
  case Dark, Light

  public init() {
    let defaults = UserDefaults.standard
    let type = defaults.string(forKey: "AppleInterfaceStyle") ?? "Light"
    self = MacTheme(rawValue: type)!
  }
}
