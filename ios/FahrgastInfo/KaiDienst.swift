import Foundation

struct KaiFehler: LocalizedError {
    let text: String
    var errorDescription: String? { text }
}

/// Spricht mit KAI — nur die öffentlichen Wege der Fahrgast-Info, keine Anmeldung mit Namen oder E-Mail.
struct KaiDienst {
    let basis: URL
    let sitzung: URLSession

    init(basis: URL = Konfiguration.basis, sitzung: URLSession = .shared) {
        self.basis = basis
        self.sitzung = sitzung
    }

    func adresse(_ pfad: String) -> URL { basis.appending(path: pfad) }

    func meldungen() async throws -> [Meldung] {
        try await holen("api/melde/feed", als: FeedAntwort.self).items
    }

    func info() async throws -> InfoAntwort {
        try await holen("api/melde/info", als: InfoAntwort.self)
    }

    /// Meldet dieses Gerät für Mitteilungen an. Gespeichert wird in KAI nur die Gerätekennung von Apple.
    /// (Die Gegenstelle in KAI — Kanal `app_ios` — kommt mit Schritt 2, zusammen mit dem Push-Schlüssel von Apple.)
    func anmelden(geraeteToken: String, sandbox: Bool) async throws -> String {
        let antwort = try await senden("api/melde/register", koerper: [
            "kanal": "app_ios",
            "consent": true,
            "geraet_token": geraeteToken,
            "apns_umgebung": sandbox ? "sandbox" : "produktion",
            "ausgabe": "bsb",
            "hp": "",
        ], als: AnmeldeAntwort.self)
        guard let token = antwort.abmeldeToken else { throw KaiFehler(text: "KAI hat die Anmeldung nicht bestätigt.") }
        return token
    }

    func abmelden(token: String) async throws {
        _ = try await senden("api/melde/unsubscribe", koerper: ["abmelde_token": token], als: AnmeldeAntwort.self)
    }

    // MARK: - Hilfen

    private func holen<T: Decodable>(_ pfad: String, als: T.Type) async throws -> T {
        var anfrage = URLRequest(url: adresse(pfad))
        anfrage.timeoutInterval = 15
        anfrage.cachePolicy = .reloadIgnoringLocalCacheData
        anfrage.setValue("application/json", forHTTPHeaderField: "Accept")
        let (daten, antwort) = try await sitzung.data(for: anfrage)
        try pruefen(daten, antwort)
        return try JSONDecoder().decode(T.self, from: daten)
    }

    private func senden<T: Decodable>(_ pfad: String, koerper: [String: Any], als: T.Type) async throws -> T {
        var anfrage = URLRequest(url: adresse(pfad))
        anfrage.httpMethod = "POST"
        anfrage.timeoutInterval = 15
        anfrage.setValue("application/json", forHTTPHeaderField: "Content-Type")
        anfrage.httpBody = try JSONSerialization.data(withJSONObject: koerper)
        let (daten, antwort) = try await sitzung.data(for: anfrage)
        try pruefen(daten, antwort)
        return try JSONDecoder().decode(T.self, from: daten)
    }

    private func pruefen(_ daten: Data, _ antwort: URLResponse) throws {
        guard let http = antwort as? HTTPURLResponse else { throw KaiFehler(text: "Keine Antwort von KAI.") }
        guard (200..<300).contains(http.statusCode) else {
            let text = (try? JSONDecoder().decode(FehlerAntwort.self, from: daten))?.error
            throw KaiFehler(text: text ?? "KAI antwortet mit Fehler \(http.statusCode).")
        }
    }
}
