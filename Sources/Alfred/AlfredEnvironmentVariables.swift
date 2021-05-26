import Foundation

public extension Alfred {
  /// Values of Alfred-specific environment variables
  /// passed to the program when the program was started.
  /// Such values are passed only if the program was started
  /// from within a workflow.
  ///
  /// Note: If this is going to be a long-running program like
  /// a daemon or a http server, that services multiple workflows,
  /// it is important to remember that these values reflect
  /// the environment **in which the program was launched**.
  static let envVarsAtInvocation: AlfredEnvironmentVariables? = {
    let env = ProcessInfo.processInfo.environment

    // alfred_preferences is an env var that's always set
    // by Alfred for processes that are started in workflows
    if env["alfred_preferences"] != nil {
      return AlfredEnvironmentVariables(env: env)
    }

    return nil
  }()
}

/**
 [Reference documentation][1]
 [1]: https://www.alfredapp.com/help/workflows/script-environment-variables/
 */
public class AlfredEnvironmentVariables {
  private let env: [String: String]!

  fileprivate init(env: [String: String]) {
    self.env = env
  }

  public lazy var prefsDir: URL =
    URL(fileURLWithPath: env["alfred_preferences"]!)

  public lazy var prefsLocalHash: String =
    env["alfred_preferences_localhash"]!

  public lazy var themeID: String =
    env["alfred_theme"]!

  public lazy var workflowID: String =
    env["alfred_workflow_bundleid"]!

  public lazy var debug: Bool =
    env["alfred_debug"]! == "1"
}
