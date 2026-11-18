import XCTest
@testable import FahrgastInfo

final class ModelleTests: XCTestCase {
    /// Genau so liefert KAI den Feed (abgerufen von kai-bsb.de/test am 18.11.2026).
    func testFeedVonKaiLesen() throws {
        let json = #"{"items":[{"id":5,"kategorie":"Kursschiff-Störung","titel":"Kursschiff-Störung","text":"Wind kommt auf","linie":"LI-KN","created_at":"2026-10-21T07:57:09.784Z"}]}"#
        let feed = try JSONDecoder().decode(FeedAntwort.self, from: Data(json.utf8))
        XCTAssertEqual(feed.items.count, 1)
        XCTAssertEqual(feed.items[0].id, 5)
        XCTAssertEqual(feed.items[0].linie, "LI-KN")
        XCTAssertEqual(feed.items[0].art, .gelb)
        XCTAssertNotNil(feed.items[0].zeitpunkt)
    }

    func testLeereFelderStoerenNicht() throws {
        let json = #"{"items":[{"id":1,"kategorie":null,"titel":null,"text":null,"linie":null,"created_at":null}]}"#
        let feed = try JSONDecoder().decode(FeedAntwort.self, from: Data(json.utf8))
        XCTAssertEqual(feed.items[0].art, .rot)
        XCTAssertNil(feed.items[0].zeitpunkt)
    }

    /// Dieselbe Farbregel wie auf der Fahrgast-Info-Seite (melde.js).
    func testFarbeWieAufDerWebseite() {
        XCTAssertEqual(MeldungsArt(kategorie: "Entwarnung"), .gruen)
        XCTAssertEqual(MeldungsArt(kategorie: "Information"), .gruen)
        XCTAssertEqual(MeldungsArt(kategorie: "Fährbetrieb normal"), .gruen)
        XCTAssertEqual(MeldungsArt(kategorie: "Verspätung"), .gelb)
        XCTAssertEqual(MeldungsArt(kategorie: "Katamaran-Störung"), .gelb)
        XCTAssertEqual(MeldungsArt(kategorie: "Ausfall"), .rot)
        XCTAssertEqual(MeldungsArt(kategorie: nil), .rot)
    }

    func testZeitInOrtszeit() throws {
        let d = try XCTUnwrap(Zeit.lesen("2026-10-21T07:57:09.784Z"))
        let spaeter = try XCTUnwrap(Zeit.lesen("2026-11-18T10:00:00Z"))
        XCTAssertEqual(Zeit.anzeigen(d, jetzt: spaeter), "21.10.2026, 09:57 Uhr")       // Sommerzeit: UTC+2
        let selberTag = try XCTUnwrap(Zeit.lesen("2026-10-21T18:00:00Z"))
        XCTAssertEqual(Zeit.anzeigen(d, jetzt: selberTag), "heute, 09:57 Uhr")
        let winter = try XCTUnwrap(Zeit.lesen("2026-11-17T15:02:00Z"))
        XCTAssertEqual(Zeit.uhrzeit(winter), "16:02")                                   // Winterzeit: UTC+1
    }

    func testZeitOhneMillisekunden() {
        XCTAssertNotNil(Zeit.lesen("2026-10-21T07:57:09Z"))
        XCTAssertNil(Zeit.lesen(""))
        XCTAssertNil(Zeit.lesen("gestern"))
    }

    func testInfoLesen() throws {
        let json = #"{"ok":true,"titel":"Fahrgast-Info Bodensee","consent_text":"Ich willige ein","datenschutz":"Verantwortlicher","aktive_meldungen":1,"kanaele":["push"],"vapid_public":"x"}"#
        let info = try JSONDecoder().decode(InfoAntwort.self, from: Data(json.utf8))
        XCTAssertEqual(info.consentText, "Ich willige ein")
        XCTAssertEqual(info.aktiveMeldungen, 1)
        XCTAssertEqual(info.kanaele, ["push"])
    }

    func testAdresseUnterDerTestumgebung() throws {
        let dienst = KaiDienst(basis: try XCTUnwrap(URL(string: "https://kai-bsb.de/test")))
        XCTAssertEqual(dienst.adresse("api/melde/feed").absoluteString, "https://kai-bsb.de/test/api/melde/feed")
    }

    func testDemoZeigtAlleDreiFarben() {
        let arten = Set(Demo.meldungen("stoerung").map { "\($0.art)" })
        XCTAssertEqual(arten, ["gruen", "gelb", "rot"])
        XCTAssertTrue(Demo.meldungen("leer").isEmpty)
    }
}
