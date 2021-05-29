import AppKit
import Foundation

/// Press Secretary in Alfred posts NSNotifications
/// containing currently selected item in Alfred.
/// reference: [Forum Post](https://bit.ly/3hXHOXD)
public struct PressSecretary {
  static let minReqVersion: Semver = Semver("4.3.0")
  static let isSupported: Bool = Alfred.version >= minReqVersion
  static let alfredDefaults = UserDefaults(suiteName: Alfred.bundleID)!
  static let pressSecKey = "experimental.presssecretary"

  static func isEnabled() -> Bool {
    alfredDefaults.bool(forKey: pressSecKey)
  }

  static func showVersionAlert() {
    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = "Alfred Version Not Supported"
    alert.informativeText = (
      "This workflow uses an Alfred feature " +
        "only available in v\(minReqVersion) and newer. " +
        "The installed Alfred version is v\(Alfred.version)."
    )
    alert.runModal()
  }

  static func showRestartDialog() {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "Alfred Restart Required"
    alert.informativeText = (
      "The workflow won't work correctly till Alfred is restarted."
    )
    alert.addButton(withTitle: "Restart Alfred Now")
    alert.addButton(withTitle: "I'll Restart Later")

    switch alert.runModal() {
    case .alertFirstButtonReturn:
      log("Restarting Alfred...")
      exec("/usr/bin/killall", "Alfred")
      exec("/usr/bin/open", Alfred.appBundlePath.path)
    default:
      log("User wants to restart Alfred later on their own.")
    }
  }

  public static func enable() {
    if !isSupported { return showVersionAlert() }
    if isEnabled() { return }
    alfredDefaults.set(true, forKey: pressSecKey)
    showRestartDialog()
  }
}


func exec(_ execPath: String, _ args: String...) {
  let task = Process()
  task.launchPath = execPath
  task.arguments = args
  task.launch()
  task.waitUntilExit()
  log("Executed: \(execPath) \(args) -> \(task.terminationStatus)")
}
