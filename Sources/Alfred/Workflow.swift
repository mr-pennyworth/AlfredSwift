import Foundation

public class Workflow {
  public let id: String!
  public let dir: URL!
  public let dataDir: URL!
  public let cacheDir: URL!
  public let name: String!
  public let author: String?
  public let description: String?
  private let plist: Plist!

  public var uid: String { get { dir.lastPathComponent } }

  fileprivate init(
    plist: Plist,
    wfDir: URL
  ) {
    dir = wfDir

    id = plist.get("bundleid")!
    dataDir = mkdIfNotPresent(Alfred.appSupportDir/"Workflow Data"/id)
    cacheDir = mkdIfNotPresent(Alfred.cacheDir/"Workflow Data"/id)

    name = plist.get("name")!
    author = plist.get("createdby")
    description = plist.get("description")

    self.plist = plist
  }
}

public extension Alfred {
  private static let fs: FileManager = FileManager.default
  private static let workflowCacheLock = NSLock()

  private static func buildWorkflowMap() -> [String: Workflow] {
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
  }

  private static var id2wf: [String: Workflow] = buildWorkflowMap()

  private static func refreshWorkflowCacheIfNeeded(forceRefresh: Bool) {
    guard forceRefresh else { return }
    id2wf = buildWorkflowMap()
  }

  static func workflows(forceRefresh: Bool = false) -> [Workflow] {
    workflowCacheLock.lock()
    defer { workflowCacheLock.unlock() }
    refreshWorkflowCacheIfNeeded(forceRefresh: forceRefresh)
    return Array(id2wf.values)
  }

  static func workflow(id: String, forceRefresh: Bool = false) -> Workflow? {
    workflowCacheLock.lock()
    defer { workflowCacheLock.unlock() }
    refreshWorkflowCacheIfNeeded(forceRefresh: forceRefresh)
    return id2wf[id]
  }
}

fileprivate func mkdIfNotPresent(_ url: URL) -> URL {
  let fs = FileManager.default
  if !fs.exists(url) {
    try? fs.createDirectory(at: url, withIntermediateDirectories: true)
  }
  return url
}
