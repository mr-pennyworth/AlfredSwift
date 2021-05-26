import Foundation

extension Alfred {
  private static let fs = FileManager.default

  static let themeID: String = {
    if let env = Alfred.envVarsAtInvocation {
      return env.themeID
    } else {
      log("Env var 'alfred_theme' not set.")
      return getThemeIdFromPlist()
    }
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
