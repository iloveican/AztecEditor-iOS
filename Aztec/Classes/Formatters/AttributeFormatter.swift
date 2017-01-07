import UIKit


/// A type that provides support for toggling compound attributes in an attributed string.
///
/// When you want to represent an attribute that does not have a 1-1 correspondence with a standard
/// attribute, it is useful to have a virtual attribute. 
/// Toggling this attribute would also toggle the attributes for its defined style.
///
protocol AttributeFormatter {

    /// Toggles an attribute in the specified range of a text storage, and returns the new 
    /// Selected Range. This is required because, in several scenarios, we may need to add a "Zero Width Space",
    /// just to get the style to render properly.
    ///
    func toggle(in text: NSMutableAttributedString, at range: NSRange) -> NSRange?

    /// Checks if the attribute is present in a given Attributed String at the specified index.
    ///
    func present(in text: NSAttributedString, at index: Int) -> Bool

    /// Apply the compound attributes to the provided attributes dictionary.
    ///
    /// - Parameter attributes: the original attributes to apply to
    /// - Returns: the resulting attributes dictionary
    ///
    func apply(to attributes: [String: Any]) -> [String: Any]

    /// Remove the compound attributes from the provided list.
    ///
    /// - Parameter attributes: the original attributes to remove from
    /// - Returns: the resulting attributes dictionary
    ///
    func remove(from attributes: [String: Any]) -> [String: Any]

    /// Checks if the attribute is present in a dictionary of attributes.
    ///
    func present(in attributes: [String: AnyObject]) -> Bool
}


// MARK: - Default Implementations
//
extension AttributeFormatter {

    /// Indicates whether the Formatter's Attributes are present in a given string, at a specified Index.
    ///
    func present(in text: NSAttributedString, at index: Int) -> Bool {
        let safeIndex = max(min(index, text.length - 1), 0)
        let attributes = text.attributes(at: safeIndex, effectiveRange: nil) as [String : AnyObject]
        return present(in: attributes)
    }
}


// MARK: - Private Helpers
//
private extension AttributeFormatter {

    /// The string to be used when adding attributes to an empty line.
    ///
    var placeholderForAttributedEmptyLine: NSAttributedString {
        // "Zero Width Space" Character
        return NSAttributedString(string: "\u{200B}")
    }

    ///
    /// Toggles the Attribute Format, into a given string, at the specified range.
    ///
    func toggleAttributes(in string: NSMutableAttributedString, at range: NSRange) {
        guard range.location < string.length else {
            return
        }

        if present(in: string, at: range.location) {
            removeAttributes(from: string, at: range)
        } else {
            applyAttributes(to: string, at: range)
        }
    }

    /// Applies the Formatter's Attributes into a given string, at the specified range.
    ///
    func applyAttributes(to string: NSMutableAttributedString, at range: NSRange) {
        let currentAttributes = string.attributes(at: range.location, effectiveRange: nil)
        let attributes = apply(to: currentAttributes)
        string.addAttributes(attributes, range: range)
    }

    /// Removes the Formatter's Attributes from a given string, at the specified range.
    ///
    func removeAttributes(from string: NSMutableAttributedString, at range: NSRange) {
        let currentAttributes = string.attributes(at: range.location, effectiveRange: nil)
        let attributes = remove(from: currentAttributes)
        string.addAttributes(attributes, range: range)
    }
}


// MARK: - Character Attribute Formatter
//
protocol CharacterAttributeFormatter: AttributeFormatter {
}

extension CharacterAttributeFormatter {

    /// Toggles the Attribute Format, into a given string, at the specified range.
    ///
    @discardableResult
    func toggle(in text: NSMutableAttributedString, at range: NSRange) {
        guard range.location < text.length else {
            return
        }

        if shouldApplyAttributes(to: text, at: range) {
            applyAttributes(to: text, at: range)
        } else {
            removeAttributes(from: text, at: range)
        }
    }
}


// MARK: - Paragraph Attribute Formatter
//
protocol ParagraphAttributeFormatter: AttributeFormatter {
}

extension ParagraphAttributeFormatter {

    @discardableResult
    func toggle(in text: NSMutableAttributedString, at range: NSRange) -> NSRange? {
        let applicationRange = self.applicationRange(for: range, in: text)
        var newSelectedRange: NSRange?

        if applicationRange.length == 0 || text.length == 0 {
            insertEmptyPlaceholderString(in: text, at: applicationRange.location)
            newSelectedRange = NSRange(location: text.length, length: 0)
        }

        toggleAttributes(in: text, at: applicationRange)

        return newSelectedRange
    }
}
