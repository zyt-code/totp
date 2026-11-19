import Testing
import TOTPCore

@Test func clipboardClearsWhenContentMatches() {
    #expect(shouldClearClipboard(current: "404162", copied: "404162"))
}

@Test func clipboardKeepsReplacedContent() {
    #expect(shouldClearClipboard(current: "something else", copied: "404162") == false)
    #expect(shouldClearClipboard(current: nil, copied: "404162") == false)
}

@Test func sixDigitCodeIsGroupedWhenEnabled() {
    #expect(groupedCode("404162", grouped: true) == "404 162")
    #expect(groupedCode("404162", grouped: false) == "404162")
    #expect(groupedCode("12345678", grouped: true) == "12345678")
}
