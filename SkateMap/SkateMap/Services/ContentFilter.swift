import Foundation

enum ContentFilterError: LocalizedError {
    case objectionableContent

    var errorDescription: String? {
        "Your text contains inappropriate content. Please revise and try again."
    }
}

enum ContentFilter {
    // Basic list of objectionable words to filter
    private static let blockedWords: Set<String> = [
        // Slurs and hate speech
        "nigger", "nigga", "faggot", "fag", "retard", "retarded",
        "chink", "spic", "kike", "wetback", "tranny",
        // Explicit sexual content
        "porn", "hentai", "xxx",
        // Violence
        "kill yourself", "kys"
    ]

    /// Returns true if the text contains objectionable content
    static func containsObjectionableContent(_ text: String) -> Bool {
        let lowered = text.lowercased()
        for word in blockedWords {
            if lowered.contains(word) {
                return true
            }
        }
        return false
    }

    /// Returns a cleaned version or nil if too objectionable
    static func isClean(_ text: String) -> Bool {
        !containsObjectionableContent(text)
    }
}
