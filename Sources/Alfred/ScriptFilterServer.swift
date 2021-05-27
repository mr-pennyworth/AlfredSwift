import Foundation
import MicroExpress

public enum ScriptFilterHandler {
  case sync(([String: String]) -> ScriptFilterResponse)
  case async(([String: String], (ScriptFilterResponse) -> ()) -> ())

  public static func from(_ f: ScriptFilter) -> ScriptFilterHandler {
    sync(f.respond)
  }

  public static func from(_ f: AsyncScriptFilter) -> ScriptFilterHandler {
    async(f.process)
  }
}

public class ScriptFilterServer {
  private let port: Int
  private let handler: ScriptFilterHandler
  public init(port: Int, handler: ScriptFilterHandler) {
    self.port = port
    self.handler = handler
  }

  public func start() {
    let app = Express()

    app.get("/") { req, res, _ in
      let query = req.queryParams()
      log("Query from alfred: \(query)")

      func respond<T: Encodable>(with response: T) {
        res.json(response)
        log("Responded to alfred: \(response)")
      }

      switch self.handler {
      case let .sync(syncFunc): respond(with: syncFunc(query))
      case let .async(asyncFunc): asyncFunc(query, { respond(with: $0) })
      }
    }

    DispatchQueue.global(qos: .utility).async {
      app.listen(self.port)
    }
  }
}

extension IncomingMessage {
  /// Explicitly ignores values of query params that have multiple values.
  /// Only the first non-empty value is included in the return value.
  /// - Returns: key-value dict of URL query params
  func queryParams() -> [String: String] {
    var params = [String: String]()
    if let queryItems = URLComponents(string: header.uri)?.queryItems {
      for qi in queryItems {
        if let oldValue: String = params[qi.name] {
          log("Param '\(qi.name)' already has value: '\(oldValue)'")
          log("Ignoring new value: '\(String(describing: qi.value))'")
        } else if let value: String = qi.value {
          params[qi.name] = value
        }
      }
    }
    return params
  }
}
