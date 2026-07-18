import Foundation

/// Compiles and runs an AppleScript snippet, returning its string result.
enum AppleScriptRunner {
    @discardableResult
    static func run(_ source: String) -> String? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if error != nil { return nil }
        return result?.stringValue
    }
}
