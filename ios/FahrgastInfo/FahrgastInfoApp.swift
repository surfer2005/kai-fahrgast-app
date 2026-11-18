import SwiftUI

@main
struct FahrgastInfoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var meldungen: MeldungenModell
    @State private var benachrichtigungen: Benachrichtigungen

    init() {
        let dienst = KaiDienst()
        _meldungen = State(initialValue: MeldungenModell(dienst: dienst))
        _benachrichtigungen = State(initialValue: Benachrichtigungen(dienst: dienst))
    }

    var body: some Scene {
        WindowGroup {
            StartAnsicht()
                .environment(meldungen)
                .environment(benachrichtigungen)
                .onAppear { appDelegate.benachrichtigungen = benachrichtigungen }
        }
    }
}
