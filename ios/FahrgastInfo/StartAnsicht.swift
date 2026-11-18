import SwiftUI
import UIKit

/// Die eine Seite der App — aufgebaut wie die Fahrgast-Info im Browser: Kopf, aktuelle Meldungen,
/// Mitteilungen aufs Handy, Datenschutzhinweise.
struct StartAnsicht: View {
    @Environment(MeldungenModell.self) private var modell
    @Environment(Benachrichtigungen.self) private var benachrichtigungen
    @Environment(\.scenePhase) private var phase
    @State private var datenschutzOffen = Start.zeige == "datenschutz"

    var body: some View {
        VStack(spacing: 0) {
            Kopf()
                .background(LinearGradient(colors: [Farbe.kopfOben, Farbe.kopfUnten], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea(edges: .top))
            ScrollViewReader { leser in
                ScrollView {
                    VStack(spacing: 16) {
                        MeldungenKarte()
                        BenachrichtigungenKarte().id("benachrichtigungen")
                        DatenschutzKarte(offen: $datenschutzOffen).id("datenschutz")
                        Fuss()
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
                .refreshable { await modell.laden() }
                .task {
                    await modell.laden()
                    await benachrichtigungen.pruefen()
                    if let ziel = Start.zeige {
                        try? await Task.sleep(for: .milliseconds(400))
                        withAnimation { leser.scrollTo(ziel, anchor: .top) }
                    }
                }
            }
        }
        .background(Farbe.hintergrund.ignoresSafeArea())
        .onChange(of: phase) { _, neu in
            guard neu == .active else { return }
            Task {
                await modell.laden()
                await benachrichtigungen.pruefen()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .neueMeldung)) { _ in
            Task { await modell.laden() }
        }
    }
}

private struct Kopf: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 1) {
                Text("Fahrgast-Info")
                    .font(.title3.weight(.heavy))
                Text("BSB Bodensee · Störungen & Betriebsinfos")
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
            if Konfiguration.istTest {
                Text("TEST")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.22), in: Capsule())
                    .foregroundStyle(.white)
                    .accessibilityLabel("Testumgebung")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }
}

private struct Karte: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Farbe.rand, lineWidth: 1))
    }
}

private extension View {
    func karte() -> some View { modifier(Karte()) }
}

private struct MeldungenKarte: View {
    @Environment(MeldungenModell.self) private var modell

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Aktuelle Meldungen")
                    .font(.headline)
                    .foregroundStyle(Farbe.text)
                Spacer()
                if modell.laedt { ProgressView() }
            }
            if let fehler = modell.fehler {
                Hinweis(text: fehler, symbol: "wifi.exclamationmark", farbe: Farbe.gelb)
            }
            if modell.meldungen.isEmpty {
                if modell.stand != nil {
                    Label("Zurzeit liegt keine Meldung vor.", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Farbe.gruenText)
                } else if modell.fehler == nil {
                    Text("Wird geladen …")
                        .font(.subheadline)
                        .foregroundStyle(Farbe.textLeise)
                }
            } else {
                ForEach(modell.meldungen) { MeldungZeile(meldung: $0) }
            }
        }
        .karte()
    }
}

private struct MeldungZeile: View {
    let meldung: Meldung

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(meldung.art.farbe)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: meldung.art.symbol)
                    Text((meldung.kategorie ?? "Meldung").uppercased())
                        .tracking(0.6)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(meldung.art.textFarbe)
                if let titel = meldung.titel, !titel.isEmpty {
                    Text(titel)
                        .font(.body.weight(.bold))
                        .foregroundStyle(Farbe.text)
                }
                if let text = meldung.text, !text.isEmpty {
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(Farbe.textLeise)
                }
                if let linie = meldung.linie, !linie.isEmpty {
                    Text("Linie: \(linie)")
                        .font(.caption)
                        .foregroundStyle(Farbe.textLeise)
                }
                Text(Zeit.anzeigen(meldung.zeitpunkt))
                    .font(.caption2)
                    .foregroundStyle(Farbe.textLeise)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 13)
            Spacer(minLength: 0)
        }
        .background(Farbe.karte)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Farbe.rand, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

private struct BenachrichtigungenKarte: View {
    @Environment(Benachrichtigungen.self) private var benachrichtigungen
    @Environment(MeldungenModell.self) private var modell

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mitteilungen aufs Handy")
                .font(.headline)
                .foregroundStyle(Farbe.text)
            switch benachrichtigungen.zustand {
            case .an:
                Label("Aktiv — neue Meldungen kommen als Mitteilung auf dieses iPhone.", systemImage: "bell.badge.fill")
                    .font(.subheadline)
                    .foregroundStyle(Farbe.gruenText)
                Button("Mitteilungen ausschalten", role: .destructive) {
                    Task { await benachrichtigungen.ausschalten() }
                }
                .buttonStyle(.bordered)
            case .abgelehnt:
                Text("Mitteilungen sind für diese App in den iPhone-Einstellungen ausgeschaltet.")
                    .font(.subheadline)
                    .foregroundStyle(Farbe.textLeise)
                Button("Einstellungen öffnen") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                .buttonStyle(.bordered)
            case .wirdAngemeldet:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Wird eingerichtet …")
                        .font(.subheadline)
                        .foregroundStyle(Farbe.textLeise)
                }
            default:
                Text("Bei Ausfällen und Verspätungen sofort Bescheid bekommen — ohne Namen und ohne E-Mail.")
                    .font(.subheadline)
                    .foregroundStyle(Farbe.textLeise)
                Button {
                    Task { await benachrichtigungen.einschalten() }
                } label: {
                    Label("Mitteilungen aktivieren", systemImage: "bell")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Farbe.akzent)
                .controlSize(.large)
                if let einwilligung = modell.info?.consentText, !einwilligung.isEmpty {
                    Text("Mit dem Aktivieren willigen Sie ein: \(einwilligung)")
                        .font(.caption)
                        .foregroundStyle(Farbe.textLeise)
                }
                if case .fehler(let text) = benachrichtigungen.zustand {
                    Hinweis(text: text, symbol: "xmark.octagon", farbe: Farbe.rot)
                }
            }
        }
        .karte()
    }
}

private struct DatenschutzKarte: View {
    @Environment(MeldungenModell.self) private var modell
    @Binding var offen: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $offen) {
            Text(modell.info?.datenschutz ?? "Die Datenschutzhinweise werden geladen, sobald eine Verbindung zu KAI besteht.")
                .font(.footnote)
                .foregroundStyle(Farbe.textLeise)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        } label: {
            Text("Datenschutzhinweise")
                .font(.headline)
                .foregroundStyle(Farbe.text)
        }
        .tint(Farbe.akzent)
        .karte()
    }
}

private struct Fuss: View {
    @Environment(MeldungenModell.self) private var modell

    var body: some View {
        VStack(spacing: 2) {
            if let stand = modell.stand {
                Text("Stand \(Zeit.uhrzeit(stand)) Uhr · zum Aktualisieren nach unten ziehen")
            }
            Text(Konfiguration.adresseText)
        }
        .font(.caption)
        .foregroundStyle(Farbe.textLeise)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

private struct Hinweis: View {
    let text: String
    let symbol: String
    let farbe: Color

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.footnote)
            .foregroundStyle(Farbe.text)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(farbe.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
    }
}
