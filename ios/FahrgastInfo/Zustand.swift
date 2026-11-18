import SwiftUI
import UIKit
import UserNotifications

/// Die Meldungen aus KAI. Ohne Netz bleibt der letzte Stand sichtbar (mit Uhrzeit), statt einer leeren Seite.
@MainActor @Observable
final class MeldungenModell {
    var meldungen: [Meldung] = []
    var info: InfoAntwort?
    var fehler: String?
    var laedt = false
    var stand: Date?

    private let dienst: KaiDienst
    private let speicher = UserDefaults.standard

    init(dienst: KaiDienst) {
        self.dienst = dienst
        if let demo = Start.demo {
            meldungen = Demo.meldungen(demo)
            info = Demo.info
            stand = Demo.jetzt
        } else {
            letztenStandLesen()
        }
    }

    func laden() async {
        guard Start.demo == nil, !laedt else { return }
        laedt = true
        defer { laedt = false }
        do {
            meldungen = try await dienst.meldungen()
            stand = Date()
            fehler = nil
            speichern()
        } catch {
            fehler = "Keine Verbindung zu KAI." + (stand != nil ? " Gezeigt wird der Stand von \(Zeit.uhrzeit(stand)) Uhr." : "")
        }
        if let i = try? await dienst.info() { info = i }
    }

    private func speichern() {
        if let d = try? JSONEncoder().encode(meldungen) { speicher.set(d, forKey: "letzteMeldungen") }
        speicher.set(stand, forKey: "letzterStand")
    }

    private func letztenStandLesen() {
        if let d = speicher.data(forKey: "letzteMeldungen"), let m = try? JSONDecoder().decode([Meldung].self, from: d) {
            meldungen = m
        }
        stand = speicher.object(forKey: "letzterStand") as? Date
    }
}

/// Mitteilungen aufs Handy: Erlaubnis im iPhone, Gerätekennung von Apple, Anmeldung in KAI.
@MainActor @Observable
final class Benachrichtigungen {
    enum Zustand: Equatable {
        case unbekannt, aus, abgelehnt, wirdAngemeldet, an
        case fehler(String)
    }

    var zustand: Zustand = .unbekannt

    private let dienst: KaiDienst
    private let speicher = UserDefaults.standard
    private var abmeldeToken: String? {
        get { speicher.string(forKey: "abmeldeToken") }
        set { speicher.set(newValue, forKey: "abmeldeToken") }
    }

    init(dienst: KaiDienst) {
        self.dienst = dienst
    }

    func pruefen() async {
        if case .wirdAngemeldet = zustand { return }
        let einstellungen = await UNUserNotificationCenter.current().notificationSettings()
        switch einstellungen.authorizationStatus {
        case .denied:
            zustand = .abgelehnt
        case .authorized, .provisional, .ephemeral:
            if abmeldeToken != nil { zustand = .an } else if case .fehler = zustand {} else { zustand = .aus }
        default:
            zustand = .aus
        }
    }

    func einschalten() async {
        do {
            let erlaubt = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            guard erlaubt else {
                zustand = .abgelehnt
                return
            }
            zustand = .wirdAngemeldet
            UIApplication.shared.registerForRemoteNotifications()
            // weiter in geraeteTokenErhalten bzw. registrierungFehlgeschlagen (AppDelegate)
        } catch {
            zustand = .fehler(error.localizedDescription)
        }
    }

    func geraeteTokenErhalten(_ token: Data) async {
        let hex = token.map { String(format: "%02x", $0) }.joined()
        do {
            abmeldeToken = try await dienst.anmelden(geraeteToken: hex, sandbox: Konfiguration.pushSandbox)
            zustand = .an
        } catch {
            zustand = .fehler("Anmeldung bei KAI nicht möglich: \(error.localizedDescription)")
        }
    }

    func registrierungFehlgeschlagen(_ fehler: Error) {
        zustand = .fehler("Dieses Gerät kann gerade keine Mitteilungen empfangen (\(fehler.localizedDescription)).")
    }

    func ausschalten() async {
        if let t = abmeldeToken { try? await dienst.abmelden(token: t) }
        abmeldeToken = nil
        zustand = .aus
    }
}

/// Verbindung zu den iPhone-Diensten: Gerätekennung für Mitteilungen und Mitteilungen bei offener App.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var benachrichtigungen: Benachrichtigungen?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in await self.benachrichtigungen?.geraeteTokenErhalten(deviceToken) }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in self.benachrichtigungen?.registrierungFehlgeschlagen(error) }
    }

    /// Kommt eine Mitteilung, während die App offen ist: trotzdem zeigen und die Liste neu laden.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        NotificationCenter.default.post(name: .neueMeldung, object: nil)
        return [.banner, .list, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        NotificationCenter.default.post(name: .neueMeldung, object: nil)
    }
}

extension Notification.Name {
    static let neueMeldung = Notification.Name("FahrgastInfoNeueMeldung")
}
