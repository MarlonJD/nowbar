import Foundation

protocol AppleScriptRunning {
    func execute(_ source: String) -> String?
}

final class NSAppleScriptRunner: AppleScriptRunning {
    func execute(_ source: String) -> String? {
        guard let script = NSAppleScript(source: source) else {
            return nil
        }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)

        guard error == nil else {
            return nil
        }

        return result.stringValue?.nilIfBlank
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmedValue = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
