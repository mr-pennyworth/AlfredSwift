import Foundation
import MicroExpress

public class ScriptFilterServer {
  private let port: Int
  private let handler: ScriptFilter
  public init(port: Int, handler: ScriptFilter) {
    self.port = port
    self.handler = handler
  }

  public func start() {
    let app = Express()

    app.get("/") { req, res, _ in
      let query = req.queryParams()
      log("Query from alfred: \(query)")

      let response = self.handler.respond(to: query)
      res.json(response)
      log("Responded to alfred: \(response)")
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
