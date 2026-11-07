import Foundation

/// Localizes a string that is chosen at runtime — a ternary of literals, a computed
/// label, or text handed to a helper as a `String` parameter.
///
/// SwiftUI only localizes string *literals* passed directly to `Text`/`Label`/`Button`.
/// Anything that arrives as a `String` value skips the string catalog, so those paths
/// go through here. Keys missing from the catalog fall back to the original text,
/// which keeps the English UI intact.
func L(_ key: String) -> String {
    String(localized: String.LocalizationValue(key))
}
