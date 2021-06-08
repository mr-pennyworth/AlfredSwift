import Foundation

public class Workflow {
  public let dir: URL!
  public let dataDir: URL!
  public let cacheDir: URL!
  public let name: String!
  private let plist: Plist!

  public var uid: String { get { dir.lastPathComponent } }

  fileprivate init(
    plist: Plist,
    wfDir: URL
  ) {
    dir = wfDir

    let id: String = plist.get("bundleid")!
    dataDir = mkdIfNotPresent(Alfred.appSupportDir/"Workflow Data"/id)
    cacheDir = mkdIfNotPresent(Alfred.cacheDir/"Workflow Data"/id)

    name = plist.get("name")!

    self.plist = plist
  }
}

public extension Alfred {
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

  static func workflows() -> [Workflow] {
    Array(id2wf.values)
  }

  static func workflow(id: String) -> Workflow? {
    id2wf[id]
  }
}

fileprivate func mkdIfNotPresent(_ url: URL) -> URL {
  let fs = FileManager.default
  if !fs.exists(url) {
    try? fs.createDirectory(at: url, withIntermediateDirectories: true)
  }
  return url
}
