import Foundation

/// Beispieldaten für die Vorführung und die Bildschirmfotos (Start mit `-demo stoerung` oder `-demo leer`).
/// Die Texte folgen dem Klick-Dummy „Störmeldung auslösen“; Uhrzeit wie dort: Mi 18.11.2026, 10:14.
enum Demo {
    static let jetzt = Zeit.lesen("2026-11-18T09:14:00Z")!

    static func meldungen(_ art: String) -> [Meldung] {
        guard art != "leer" else { return [] }
        return [
            Meldung(id: 3, kategorie: "Störung",
                    titel: "Fähre Friedrichshafen – Romanshorn: Kursschiff statt Fähre",
                    text: "Die Fähre der BSB fällt aus. Ihre Fahrten fahren bis auf Weiteres als Personenersatzverkehr mit einem Kursschiff, zu den gewohnten Abfahrtszeiten. In Friedrichshafen fährt das Kursschiff ab Platz 2. Kraftfahrzeuge können nicht mitfahren. Die Fähre der SBS fährt planmäßig.",
                    linie: "Fähre Friedrichshafen – Romanshorn", createdAt: "2026-11-18T09:14:00Z"),
            Meldung(id: 2, kategorie: "Ausfall",
                    titel: "Katamaran Friedrichshafen – Konstanz: Katamaran-Ausfall",
                    text: "Wegen eines Katamaran-Ausfalls entfallen heute diese Fahrten: ab Friedrichshafen 11:00, 13:00, 15:00 Uhr; ab Konstanz 12:00, 14:00, 16:00 Uhr. Alle anderen Fahrten finden planmäßig statt.",
                    linie: "Katamaran Friedrichshafen – Konstanz", createdAt: "2026-11-18T08:40:00Z"),
            Meldung(id: 1, kategorie: "Entwarnung",
                    titel: "Kursschiff Lindau – Bregenz fährt wieder",
                    text: "Die Störung ist beendet, alle Fahrten finden wieder planmäßig statt.",
                    linie: nil, createdAt: "2026-11-17T15:02:00Z"),
        ]
    }

    static let info = InfoAntwort(
        titel: "Fahrgast-Info Bodensee",
        consentText: "Ich willige ein, dass die Bodensee-Schiffsbetriebe mir Betriebs- und Störungsinformationen als Mitteilung auf dieses Gerät senden. Widerruf jederzeit durch Ausschalten.",
        datenschutz: "Verantwortlicher\nBodensee-Schiffsbetriebe GmbH, Hafenstraße 6, 78462 Konstanz.\n\n(Vorführung — in der App stehen hier die Datenschutzhinweise aus KAI.)",
        aktiveMeldungen: 2,
        kanaele: ["push"])
}
