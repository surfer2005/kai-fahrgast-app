import Foundation

/// Wohin die App spricht. Die Basisadresse steht beim Bauen in der Info.plist (`KAIBasis`, aus `KAI_BASIS` in project.yml);
/// Vorgabe ist die Testumgebung von KAI.
enum Konfiguration {
    static let vorgabe = "https://kai-bsb.de/test"

    static var basis: URL {
        let text = (Bundle.main.object(forInfoDictionaryKey: "KAIBasis") as? String) ?? vorgabe
        return URL(string: text.isEmpty ? vorgabe : text) ?? URL(string: vorgabe)!
    }

    /// Testumgebung? Dann steht „TEST“ im Kopf — sonst sieht man der App nicht an, wohin sie spricht.
    static var istTest: Bool { basis.path.hasPrefix("/test") }

    static var adresseText: String { (basis.host ?? "") + basis.path }

    /// Aus Xcode installierte Fassungen bekommen Mitteilungen über Apples Testdienst, TestFlight- und Store-Fassungen über den echten.
    #if DEBUG
    static let pushSandbox = true
    #else
    static let pushSandbox = false
    #endif
}

/// Startargumente für Vorführung und Bildschirmfotos (z. B. `-demo stoerung -zeige datenschutz`).
enum Start {
    static func wert(_ name: String) -> String? {
        let argumente = ProcessInfo.processInfo.arguments
        guard let i = argumente.firstIndex(of: "-" + name), i + 1 < argumente.count else { return nil }
        return argumente[i + 1]
    }
    /// `stoerung` = drei Beispielmeldungen, `leer` = keine Meldung — ohne Netz, damit Bildschirmfotos immer gleich aussehen.
    static var demo: String? { wert("demo") }
    /// Zu welchem Abschnitt beim Start gescrollt wird: `benachrichtigungen` oder `datenschutz`.
    static var zeige: String? { wert("zeige") }
}

enum Uhr {
    static var jetzt: Date { Start.demo != nil ? Demo.jetzt : Date() }
}
