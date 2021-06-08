import AppKit
import Foundation

/// Press Secretary in Alfred posts NSNotifications
/// containing currently selected item in Alfred.
/// reference: [Forum Post](https://bit.ly/3hXHOXD)
struct PressSecretary {
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

  fileprivate static func enable() {
    if !isSupported { return showVersionAlert() }
    if isEnabled() { return }
    alfredDefaults.set(true, forKey: pressSecKey)
    showRestartDialog()
  }
}

public extension Alfred {
  struct SelectedItem: Codable {
    public let title: String?
    public let subtext: String?
    public let quicklookurl: URL?
    public let workflowuid: String?
    public let uid: String?
  }

  private static var notificationObserverAdded: Bool = false
  private static var frameChangeHandlers: [(NSRect) -> ()] = []
  private static var hideHandlers: [() -> ()] = []
  private static var selectHandlers: [(SelectedItem) -> ()] = []

  private static func addNotifObserver() {
    if !notificationObserverAdded {
      PressSecretary.enable()
      DistributedNotificationCenter.default().addObserver(
        self,
        selector: #selector(handleAlfredNotification),
        name: NSNotification.Name(rawValue: "alfred.presssecretary"),
        object: nil,
        suspensionBehavior: .deliverImmediately
      )
      notificationObserverAdded = true
    }
  }

  /// Callback for whenever Alfred's window's dimensions or position changes
  static func onFrameChange(callback: @escaping (NSRect) -> ()) {
    addNotifObserver()
    frameChangeHandlers.append(callback)
  }

  /// Callback for whenever Alfred's window is no longer visible / destroyed
  static func onHide(callback: @escaping () -> ()) {
    addNotifObserver()
    hideHandlers.append(callback)
  }

  /// Callback for whenever the user selectd one of Alfred's items
  static func onItemSelect(callback: @escaping (SelectedItem) -> ()) {
    addNotifObserver()
    selectHandlers.append(callback)
  }

  @objc private static func handleAlfredNotification(
    notification: NSNotification
  ) {
    let notif = notification.userInfo! as! [String: Any]
    let notifType = notif["announcement"] as! String

    if let windowFrameStr = notif["windowframe"] as? String {
      let frame: NSRect = NSRectFromString(windowFrameStr)
      log("Alfred window NSRect: \(frame)")
      for handler in frameChangeHandlers {
        handler(frame)
      }
    }

    if notifType == "window.hidden" {
      log("Alfred window hidden")
      for handler in hideHandlers {
        handler()
      }
    }

    if ["selection.changed", "context.changed"].contains(notifType) {
      if let selection = notif["selection"] as? [String: Any] {
        log("Raw Alfred selection: \(selection)")
        var qlURL: URL? = nil
        if let url = selection["quicklookurl"] as? String {
          qlURL = URL(string: url) ?? URL(fileURLWithPath: url)
        }
        var uid: String? = nil
        if let resultuid = selection["resultuid"] as? String {
          uid =
            resultuid
              .split(separator: ".", omittingEmptySubsequences: false)
              .dropFirst().joined(separator: ".")
        }
        let selectedItem = SelectedItem(
          title: selection["title"] as? String,
          subtext: selection["subtext"] as? String,
          quicklookurl: qlURL,
          workflowuid: selection["workflowuid"] as? String,
          uid: uid
        )
        log("Parsed Alfred selection: \(selectedItem)")
        for handler in selectHandlers {
          handler(selectedItem)
        }
      }
    }
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
