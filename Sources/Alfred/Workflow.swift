import Foundation

class Workflow {
  let dir: URL!
  let dataDir: URL!
  let cacheDir: URL!
  private let plist: Plist!

  fileprivate init(
    plist: Plist,
    wfDir: URL
  ) {
    dir = wfDir

    let id: String = plist.get("bundleid")!
    dataDir = Alfred.appSupportDir/"Workflow Data"/id
    cacheDir = Alfred.cacheDir/"Workflow Data"/id

    self.plist = plist
  }
}

extension Alfred {
  private static let fs: FileManager = FileManager.default

  private static var id2wf: [String: Workflow] = {
    var dict = [String: Workflow]()
    for wfDir in (prefsDir/"workflows").subDirs() {
      let plPath = wfDir/"info.plist"
      if fs.exists(plPath) {
        let plist = Plist(path: plPath)
        if let wfId: String = plist.get("bundleid") {
          dict[wfId] = Workflow(plist: plist, wfDir: wfDir)
        } else {
          log("Error: no bundle ID in: \(plPath.path)")
        }
      } else {
        log("No plist found: \(plPath.path)")
      }
    }
    return dict
  }()

  static func workflow(id: String) -> Workflow? {
    id2wf[id]
  }
}
