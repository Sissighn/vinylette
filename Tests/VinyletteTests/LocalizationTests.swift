import XCTest

@testable import Vinylette

/// Guards the three localization sources against drifting apart: the
/// `Localizable.xcstrings` catalog, both compiled `.lproj` tables, and the
/// keys actually referenced from code.
final class LocalizationTests: XCTestCase {
    private static let languages = ["en", "de"]

    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // LocalizationTests.swift
        .deletingLastPathComponent()  // VinyletteTests
        .deletingLastPathComponent()  // Tests

    private static let resourcesURL =
        repoRoot
        .appendingPathComponent("Sources/Vinylette/Resources")

    // MARK: - Catalog access

    private func catalogKeys() throws -> [String: Set<String>] {
        let url = Self.resourcesURL.appendingPathComponent("Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let json = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let strings = try XCTUnwrap(json["strings"] as? [String: Any])

        var result: [String: Set<String>] = [:]
        for (key, value) in strings {
            let localizations = (value as? [String: Any])?["localizations"] as? [String: Any]
            result[key] = Set(localizations?.keys ?? [String: Any]().keys)
        }
        return result
    }

    private func stringsFileKeys(language: String) throws -> Set<String> {
        let url = Self.resourcesURL
            .appendingPathComponent("\(language).lproj/Localizable.strings")
        let data = try Data(contentsOf: url)
        // PropertyListSerialization reads both the generated XML form and the
        // classic "key" = "value"; text form.
        let table = try XCTUnwrap(
            try PropertyListSerialization.propertyList(from: data, format: nil)
                as? [String: String]
        )
        return Set(table.keys)
    }

    private func keysReferencedInCode() throws -> Set<String> {
        let sourcesURL = Self.repoRoot.appendingPathComponent("Sources")
        let enumerator = try XCTUnwrap(
            FileManager.default.enumerator(
                at: sourcesURL, includingPropertiesForKeys: nil
            ))

        // With the typed `L10n` accessors, every key literal lives in
        // Localization.swift; the scan still covers stray direct lookups.
        var keys: Set<String> = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let content = try String(contentsOf: url, encoding: .utf8)
            keys.formUnion(
                try firstCaptures(
                    in: content, pattern: #"text\("([^"]+)"\)"#
                ))
        }
        return keys
    }

    private func firstCaptures(in content: String, pattern: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(content.startIndex..., in: content)
        return regex.matches(in: content, range: range).compactMap { match in
            Range(match.range(at: 1), in: content).map { String(content[$0]) }
        }
    }

    // MARK: - Tests

    func testEveryCatalogKeyIsTranslatedIntoEveryLanguage() throws {
        let catalog = try catalogKeys()
        XCTAssertFalse(catalog.isEmpty)

        for (key, languages) in catalog {
            for language in Self.languages {
                XCTAssertTrue(
                    languages.contains(language),
                    "'\(key)' is missing its \(language) translation")
            }
        }
    }

    func testCompiledStringsTablesMatchTheCatalog() throws {
        let catalog = Set(try catalogKeys().keys)

        for language in Self.languages {
            let table = try stringsFileKeys(language: language)
            XCTAssertEqual(
                table, catalog,
                "\(language).lproj/Localizable.strings is out of sync with the catalog")
        }
    }

    func testEveryKeyReferencedInCodeExistsInTheCatalog() throws {
        let catalog = Set(try catalogKeys().keys)
        let referenced = try keysReferencedInCode()
        XCTAssertFalse(referenced.isEmpty)

        XCTAssertTrue(
            referenced.subtracting(catalog).isEmpty,
            "Missing translations for: \(referenced.subtracting(catalog).sorted())")
    }

    func testTypedAccessorsResolveToTranslationsNotKeys() {
        // An unresolved lookup returns the key itself, so any accessor still
        // equal to its key means the bundle wiring is broken.
        let samples = [
            (L10n.Menu.quit, "menu.quit"),
            (L10n.Design.sleeve, "design.sleeve"),
            (L10n.Permission.missing, "permission.missing"),
            (
                PlaybackError(kind: .artwork, diagnostic: "", fallback: .idle).message,
                "spotify.error.artwork"
            ),
        ]

        for (resolved, key) in samples {
            XCTAssertFalse(resolved.isEmpty)
            XCTAssertNotEqual(resolved, key, "'\(key)' did not resolve to a translation")
        }
    }

    func testNoOrphanedCatalogKeys() throws {
        let catalog = Set(try catalogKeys().keys)
        let referenced = try keysReferencedInCode()

        XCTAssertTrue(
            catalog.subtracting(referenced).isEmpty,
            "Unused catalog keys: \(catalog.subtracting(referenced).sorted())")
    }
}
