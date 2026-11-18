# Fahrgast-Info als App (BSB Bodensee)

Eigene Apps für iPhone und Android zur Fahrgast-Info der Bodensee-Schiffsbetriebe — Entscheidung vom 18.11.2026:
zwei eigene, schlanke Apps (Swift für das iPhone, Kotlin für Android) statt einer eingepackten Webseite; die
Fahrgast-Info im Browser (`kai-bsb.de/melde`) bleibt daneben bestehen.

Quelle liegt im KAI-Repository unter `edge/fahrgast-app/` und wird in das öffentliche GitHub-Repository
`surfer2005/kai-fahrgast-app` gespiegelt; dort baut GitHub die App auf einem Mac.

## Stand: Schritt 1 — iPhone-App im Simulator

- **Eine Seite wie die Fahrgast-Info:** blauer Kopf, aktuelle Meldungen (Farben wie auf der Webseite: grün Entwarnung/
  Information, gelb Störung/Verspätung, rot alles andere), „Mitteilungen aufs Handy“, Datenschutzhinweise aus KAI.
- **Ohne Netz** bleibt der letzte Stand mit Uhrzeit sichtbar. Zum Aktualisieren nach unten ziehen; beim Öffnen und bei
  einer Mitteilung lädt sie selbst neu.
- **Keine Anmeldung mit Namen oder E-Mail.** Für Mitteilungen meldet sich das Gerät mit seiner Kennung von Apple bei KAI an
  (`POST /api/melde/register`, Kanal `app_ios`). Die Gegenstelle in KAI und der Versand über Apples Push-Dienst kommen mit Schritt 2.
- Spricht mit der **Testumgebung** (`KAI_BASIS` in `ios/project.yml`); im Kopf steht dann „TEST“.

GitHub baut bei jedem Hochladen auf `main` (`.github/workflows/ios.yml`): Projekt aus `ios/project.yml` erzeugen
(XcodeGen), bauen, Prüfungen laufen lassen (`ios/FahrgastInfoTests`), danach Bildschirmfotos im Simulator
(`ios/werkzeuge/bildschirmfotos.sh`, Vorführdaten mit `-demo stoerung|leer`, einmal echt gegen KAI-Test). Die Fotos liegen
am Lauf als Anhang „bildschirmfotos“.

## Selbst ausprobieren auf dem Mac (kostenlos)

1. Xcode aus dem Mac App Store installieren (kostenlos; beim ersten Start die iOS-Plattform mitladen).
2. Bei GitHub am letzten Lauf (Actions → iOS) den Anhang **FahrgastInfo-Xcode** herunterladen und entpacken.
3. `FahrgastInfo.xcodeproj` doppelklicken, oben als Ziel einen iPhone-Simulator wählen (z. B. „iPhone 16“), ▶ drücken.
   Kein Apple-Konto, kein Kabel, keine 7-Tage-Grenze.
4. Mitteilung ausprobieren: in der App „Mitteilungen aktivieren“ → erlauben, dann `test-mitteilung.apns` auf das
   Simulator-Fenster ziehen. (Eine echte Anmeldung bei Apple geht im Simulator ohne Entwicklerkonto nicht — die App meldet das.)

Auf dem eigenen iPhone ohne Entwicklerkonto: mit kostenloser Apple-ID über Xcode (Kabel, Entwicklermodus am iPhone),
läuft dann 7 Tage und ohne Mitteilungen. Mit Mitteilungen nur mit Apple-Entwicklerprogramm (TestFlight).

## Nächste Schritte

2. Auf dem eigenen iPhone über TestFlight: Apple-Entwicklerprogramm, Signatur und Hochladen durch GitHub,
   Push-Schlüssel von Apple in KAI (Test), Gegenstelle in KAI.
3. Ausgaben BSB und Katamaran, „Meine Linien“.
4. Android-App (Kotlin), Push über Firebase Cloud Messaging.
