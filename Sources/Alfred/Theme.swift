import Foundation


// Alfred's theme editor gives four translucency options
// for Alfred's window:
// 1. No Blur
// 2. Visual Effect Light
// 3. Visual Effect Dark
// 4. Classic Blur (Deprecated)
//
// The four choices above are encoded in the theme's JSON
// as:
// 1. visualEffectMode: null, window.blur: 0
// 2. visualEffectMode: 1,    window.blur: 0
// 3. visualEffectMode: 2,    window.blur: 0
// 4. visualEffectMode: null, window.blur: int in [0, 40]
public enum VisualEffect: Equatable {
  case classicBlur(blur: Int)
  case light
  case dark
}

public extension Alfred {
  private static let fs = FileManager.default

  static let themeID: String = {
    if let env = Alfred.envVarsAtInvocation {
      return env.themeID
    } else {
      log("Env var 'alfred_theme' not set.")
      return getThemeIdFromPlist()
    }
  }()

  static let themePath: URL = {
    if let bundledThemePath = bundledThemeID2Filename[themeID] {
      return bundledThemesDir/bundledThemePath
    } else {
      return themesDir/themeID/"theme.json"
    }
  }()

  static let theme: [String: Any] = {
    if fs.exists(themePath) {
      if let themeJson = jsonObj(contentsOf: themePath) {
        if let theme = themeJson["alfredtheme"] as? [String: Any] {
          return flattenJsonObj(arraylessJsonObj: theme)
        } else {
          log("Error: Theme JSON lacks key 'alfredtheme': \(themePath.path)")
        }
      } else {
        log("Error: Failed to load theme JSON from: \(themePath.path)")
      }
    } else {
      log("Error: Theme file doesn't exist: \(themePath.path)")
    }
    return [String: Any]()
  }()

  /// Example:
  /// ```
  /// :root {
  ///   --separator-color: #F9915700;
  ///   --search-text-font: "System Light";
  ///   --window-paddingVertical: 10px;
  ///   --result-shortcut-size: 16px;
  ///   --window-blur: 0%;
  ///   ...
  /// }
  /// ```
  static let themeCSS: String =
    """
    :root {
      \(theme.map(kv2cssLine).joined(separator: "\n  "))
    }
    """
 
  static let visualEffect: VisualEffect = {
    switch (theme["visualEffectMode"] as? Int) ?? 0 {
    case 0: .classicBlur(blur: (theme["window-blur"] as? Int) ?? 0)
    case 1: .light
    case 2: .dark
    default: .classicBlur(blur: 0)
    }
  }()
  
  private static func kv2cssLine(key: String, value: Any) -> String {
    switch value {
    case let num as Int:
      // as it turns out, as of May 2021,
      // except for blur values,
      // all other integer values are pixels
      if key.hasSuffix("blur") {
        return "--\(key): \(num)%;"
      } else {
        return "--\(key): \(num)px;"
      }
    case let str as String:
      if str.hasPrefix("#") {
        // shouldn't quote colors
        return "--\(key): \(str);"
      } else {
        // need to quote everything else that's a string
        return "--\(key): \"\(str)\";"
      }
    default:
      log("Error: couldn't convert to css: {\(key): \(value)}")
      return ""
    }
  }

  private static let themesDir: URL = prefsDir/"themes"
  private static let bundledThemesDir: URL = {
    let app = appBundlePath
    return app/"Contents"/"Frameworks"/"Alfred Framework.framework"/"Resources"
  }()

  private static let defaultThemeID: String = {
    switch MacTheme() {
    case .Dark: return "theme.bundled.dark"
    case .Light: return "theme.bundled.default"
    }
  }()

  private static let themePlistKey: String = {
    switch MacTheme() {
    case .Dark: return "darkthemeuid"
    case .Light: return "lightthemeuid"
    }
  }()

  private static func getThemeIdFromPlist() -> String {
    log("Getting theme ID from plist.")
    let plistPath = localPrefsDir/"appearance"/"prefs.plist"
    if fs.exists(plistPath) {
      if let themeId: String = Plist(path: plistPath).get(themePlistKey) {
        return themeId
      }
    }
    return defaultThemeID
  }
}

fileprivate let bundledThemeID2Filename: [String: String] = [
  "theme.bundled.classic"     : "Alfred Classic.alfredappearance",
  "theme.bundled.dark"        : "Alfred Dark.alfredappearance",
  "theme.bundled.default"     : "Alfred.alfredappearance",
  "theme.bundled.frostyteal"  : "Frosty Teal.alfredappearance",
  "theme.bundled.highcontrast": "High Contrast.alfredappearance",
  "theme.bundled.modern"      : "Alfred Modern.alfredappearance",
  "theme.bundled.modernavenir": "Modern Avenir.alfredappearance",
  "theme.bundled.moderndark"  : "Alfred Modern Dark.alfredappearance",
  "theme.bundled.osx"         : "Alfred macOS.alfredappearance",
  "theme.bundled.osxdark"     : "Alfred macOS Dark.alfredappearance",
]
