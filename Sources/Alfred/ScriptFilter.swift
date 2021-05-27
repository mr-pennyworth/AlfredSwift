import Foundation

public protocol ScriptFilter {
  func respond(to query: [String: String]) -> ScriptFilterResponse
}

public protocol AsyncScriptFilter {
  func process(
    query: [String: String],
    then: (ScriptFilterResponse) -> ()
  )
}

/// Alfred's script filter response [JSON spec][1]
/// [1]: https://www.alfredapp.com/help/workflows/inputs/script-filter/json/
public struct ScriptFilterResponse: Codable {
  // TODO: Implement rerun, vars, session vars etc

  public var items: [Item] = [Item]()
  public init(items: [Item]? = nil) {
    if let items = items {
      self.items = items
    }
  }

  public struct Item: Codable {
    /// When this item is actioned, this is what will be passed
    /// through to the connected output action.
    ///
    /// Although optional according to the spec,
    /// we require arg because the spec strongly recommends so.
    public var arg: String = ""

    /// This is a unique identifier for the item.
    /// It helps Alfred learn about this item for
    /// subsequent sorting and ordering of the user's actioned results.
    ///
    /// It is important that you use the same UID throughout subsequent
    /// executions of your script to take advantage of Alfred's knowledge
    /// and sorting. If you would like Alfred to always show the results
    /// in the order you return them from your script, exclude the UID field.
    public var uid: String?

    public var title: String = ""
    public var subtitle: String?

    /// - `true`: Alfred will action this item when the user presses return.
    /// - `false`: Alfred will do nothing.
    /// - `nil`: Treated same as `true`.
    public var valid: Bool?

    /// The `match` field enables you to define what Alfred matches against
    /// when the workflow is set to "Alfred Filters Results".
    /// If `match` is present, it fully replaces matching
    /// on the `title` property.
    /// Note that the match field is always treated as case insensitive,
    /// and intelligently treated as diacritic insensitive.
    /// If the search query contains a diacritic,
    /// the match becomes diacritic sensitive.
    /// This option pairs well with the "Alfred Filters Results".
    public var match: String?

    /// This is populated into Alfred's search field
    /// if the user auto-completes the selected result (⇥ by default).
    public var autocomplete: String?

    /// A Quick Look URL which will be visible if the user uses
    /// the Quick Look feature within Alfred (tapping shift, or cmd+y).
    /// Both file paths and web URLs are acceptable.
    public var quicklookurl: URL?

    /// - nil: Alfred treats `arg` as just a string.
    /// - .file: Alfred treats `arg` as a file on the system.
    /// if the `arg` is not a valid path, Alfred won't show the item.
    /// This has a small performance penalty.
    /// - .fileSkipCheck: same as `.file`, but Alfred won't validate path.
    /// the item will be shown irrespective of `arg` being valid path.
    public var type: Typ?

    /// These allow the user to perform actions on the item
    /// like a file just like they can with Alfred's built-in file filters.
    public enum Typ: String, Codable {
      case file = "file"
      case fileSkipCheck = "file:skipcheck"
    }

    /// Defines the text the user will get when
    /// copying the selected item with ⌘C or
    /// displaying large type with ⌘L.
    public var text: Text?

    /// If these are not defined,
    /// you will inherit Alfred's standard behaviour where
    /// the `arg` is copied to the Clipboard or used for Large Type.
    public struct Text: Codable {
      public var copy: String?
      public var largetype: String?
      public init(
        copy: String? = nil,
        largetype: String? = nil
      ) {
        self.copy = copy
        self.largetype = largetype
      }
    }

    /// The icon displayed in the result row.
    public var icon: Icon?

    /// [Detailed documentation][1]
    /// [1]: https://pkg.go.dev/github.com/deanishe/awgo@v0.28.0#Icon
    public class Icon: Codable {
      private let type: String?
      private let path: String

      private init(type: String? = nil, path: String) {
        self.type = type
        self.path = path
      }

      /// Use image at `filePath` as an icon.
      public static func fromImage(at filePath: URL) -> Icon {
        Icon(path: filePath.path)
      }

      /// Use the standard icon for the given [UTI][1].
      /// [1]: https://en.wikipedia.org/wiki/Uniform_Type_Identifier
      public static func forFileType(uti: String) -> Icon {
        Icon(type: "filetype", path: uti)
      }

      /// Use the icon of the file at `filePath`.
      public static func ofFile(at filePath: URL) -> Icon {
        Icon(type: "fileicon", path: filePath.path)
      }
    }

    /// The mod element gives you control over how the modifier keys react.
    /// You can now define the valid attribute to mark if the result is valid
    /// based on the modifier selection and set a different arg to be passed out
    /// if actioned with the modifier.
    public var mods: Mods?

    public struct Mods: Codable {
      public var cmd: Mod?
      public var alt: Mod?
      public static func mods(
        cmd: Mod? = nil,
        alt: Mod? = nil
      ) -> Mods {
        var m = Mods()
        m.cmd = cmd
        m.alt = alt
        return m
      }
    }

    /// When the item is actioned while the modifier key is pressed,
    /// these values override the original item's values.
    public struct Mod: Codable {
      public var arg: String?
      public var subtitle: String?
      public var valid: Bool?
      public var icon: Icon?
      public static func mod(
        arg: String? = nil,
        subtitle: String? = nil,
        valid: Bool? = nil,
        icon: Icon? = nil
      ) -> Mod {
        var m = Mod()
        m.arg = arg
        m.subtitle = subtitle
        m.valid = valid
        m.icon = icon
        return m
      }
    }

    public static func item(
      arg: String,
      title: String,
      uid: String? = nil,
      subtitle: String? = nil,
      valid: Bool? = nil,
      match: String? = nil,
      autocomplete: String? = nil,
      quicklookurl: URL? = nil,
      type: Typ? = nil,
      text: Text? = nil,
      icon: Icon? = nil,
      mods: Mods? = nil
    ) -> Item {
      var i = Item()
      i.arg = arg
      i.title = title
      i.uid = uid
      i.subtitle = subtitle
      i.valid = valid
      i.match = match
      i.autocomplete = autocomplete
      i.quicklookurl = quicklookurl
      i.type = type
      i.text = text
      i.icon = icon
      i.mods = mods
      return i
    }
  }

  func asJsonStr(sortKeys: Bool = false) -> String {
    let encoder = JSONEncoder()

    encoder.outputFormatting.update(with: .prettyPrinted)
    if sortKeys {
      encoder.outputFormatting.update(with: .sortedKeys)
    }
    if #available(macOS 10.15, *) {
      encoder.outputFormatting.update(with: .withoutEscapingSlashes)
    }

    let jsonData = try! encoder.encode(self)
    return String(data: jsonData, encoding: .utf8)!
  }
}
