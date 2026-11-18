import Foundation

/// Eine Meldung aus KAI (`GET /api/melde/feed`) — dieselben Felder wie auf der Fahrgast-Info-Seite.
struct Meldung: Codable, Identifiable, Equatable {
    let id: Int
    let kategorie: String?
    let titel: String?
    let text: String?
    let linie: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, kategorie, titel, text, linie
        case createdAt = "created_at"
    }

    var art: MeldungsArt { MeldungsArt(kategorie: kategorie) }
    var zeitpunkt: Date? { Zeit.lesen(createdAt) }
}

struct FeedAntwort: Decodable {
    let items: [Meldung]
}

/// `GET /api/melde/info` — Einwilligungstext und Datenschutzhinweise kommen aus KAI, damit sie überall gleich lauten.
struct InfoAntwort: Decodable {
    let titel: String?
    let consentText: String?
    let datenschutz: String?
    let aktiveMeldungen: Int?
    let kanaele: [String]?

    enum CodingKeys: String, CodingKey {
        case titel, datenschutz, kanaele
        case consentText = "consent_text"
        case aktiveMeldungen = "aktive_meldungen"
    }
}

struct AnmeldeAntwort: Decodable {
    let ok: Bool?
    let abmeldeToken: String?

    enum CodingKeys: String, CodingKey {
        case ok
        case abmeldeToken = "abmelde_token"
    }
}

struct FehlerAntwort: Decodable {
    let error: String?
}

/// Farbe einer Meldung — dieselbe Regel wie auf der Fahrgast-Info-Seite (server/src/routes/melde.js):
/// Entwarnung, Normal, Information grün · Verspätung, Störung gelb · alles andere rot.
enum MeldungsArt: Equatable {
    case gruen, gelb, rot

    init(kategorie: String?) {
        let k = (kategorie ?? "").lowercased()
        if ["entwarnung", "normal", "information"].contains(where: { k.contains($0) }) {
            self = .gruen
        } else if ["verspät", "verspaet", "störung", "stoerung"].contains(where: { k.contains($0) }) {
            self = .gelb
        } else {
            self = .rot
        }
    }
}

/// KAI liefert Zeitpunkte als ISO-Text in UTC; angezeigt wird Ortszeit am Bodensee.
enum Zeit {
    static let zone = TimeZone(identifier: "Europe/Berlin")!

    static func lesen(_ text: String?) -> Date? {
        guard let text, !text.isEmpty else { return nil }
        let mit = ISO8601DateFormatter()
        mit.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = mit.date(from: text) { return d }
        let ohne = ISO8601DateFormatter()
        ohne.formatOptions = [.withInternetDateTime]
        return ohne.date(from: text)
    }

    /// „heute, 09:57 Uhr“ bzw. „21.10.2026, 09:57 Uhr“.
    static func anzeigen(_ d: Date?, jetzt: Date = Uhr.jetzt) -> String {
        guard let d else { return "" }
        var kalender = Calendar(identifier: .gregorian)
        kalender.timeZone = zone
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.timeZone = zone
        f.dateFormat = kalender.isDate(d, inSameDayAs: jetzt) ? "'heute,' HH:mm 'Uhr'" : "dd.MM.yyyy, HH:mm 'Uhr'"
        return f.string(from: d)
    }

    static func uhrzeit(_ d: Date?) -> String {
        guard let d else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.timeZone = zone
        f.dateFormat = "HH:mm"
        return f.string(from: d)
    }
}
