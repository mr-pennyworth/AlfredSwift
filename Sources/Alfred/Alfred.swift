import Foundation

class Alfred {
  private static let fs: FileManager = FileManager.default
  private static let home: URL = fs.homeDirectoryForCurrentUser

  private static let appBundlePath: URL =
    URL(fileURLWithPath: "/Applications/Alfred 4.app")

  private static let alfredPlist: Plist =
    Plist(path: appBundlePath/"Contents"/"Info.plist")

  private static let bundleID: String = alfredPlist.get(
    "CFBundleIdentifier",
    orElse: "com.runningwithcrayons.Alfred"
  )

  static let appSupportDir: URL =
    home/"Library"/"Application Support"/"Alfred"

  static let cacheDir: URL =
    home/"Library"/"Caches"/bundleID

  static let prefsDir: URL = {
    let prefsJsonPath = appSupportDir/"prefs.json"
    if let dict = jsonObj(contentsOf: prefsJsonPath) {
      if let dirPath = dict["current"] as? String {
        return URL(fileURLWithPath: dirPath)
      }
    }
    return URL(fileURLWithPath: "/dev/null")
  }()

  static let isInstalled: Bool = fs.exists(appBundlePath)

  static let build: Int =
    Int(alfredPlist.get("CFBundleVersion", orElse: "0"))!

  static let version: Semver = Semver(alfredPlist.get(
    "CFBundleShortVersionString",
    orElse: "0.0.0"
  ))!

  // Press Secretary in Alfred posts NSNotifications
  // containing currently selected item in Alfred.
  // reference: https://bit.ly/3hXHOXD
  private static let minPressSecretaryBuild: Int = 1203

  static let hasPressSecretary: Bool = build >= minPressSecretaryBuild
}
