import Foundation
import os

/// Error surfaced by a failed AppleScript compilation or execution.
struct AppleScriptError: Error {
    let code: Int
    let message: String

    /// macOS refused to send Apple Events to the target app because the user
    /// has not granted (or has revoked) the Automation permission.
    var isPermissionDenied: Bool { code == -1743 }
}

/// Compiles and runs AppleScript snippets, returning their string result.
enum AppleScriptRunner {
    private static let logger = Logger(
        subsystem: "com.setayesh.vinylette", category: "applescript"
    )

    @discardableResult
    static func run(_ source: String) -> Result<String, AppleScriptError> {
        guard let script = NSAppleScript(source: source) else {
            let error = AppleScriptError(code: 0, message: "Could not create NSAppleScript")
            logger.error("\(error.message, privacy: .public)")
            return .failure(error)
        }

        var errorInfo: NSDictionary?
        let output = script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let error = AppleScriptError(
                code: errorInfo[NSAppleScript.errorNumber] as? Int ?? 0,
                message: errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            )
            logger.error("AppleScript failed (\(error.code)): \(error.message, privacy: .public)")
            return .failure(error)
        }
        return .success(output.stringValue ?? "")
    }
}
