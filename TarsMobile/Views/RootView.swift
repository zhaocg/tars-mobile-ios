import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        ChatView(viewModel: viewModel)
            .onAppear {
                configureViewModel()
            }
            .onChange(of: settings.connectionFingerprint) { _, _ in
                configureViewModel()
            }
    }

    private func configureViewModel() {
        viewModel.configure(
            baseURL: settings.serverBaseURL,
            sessionID: settings.sessionID,
            connectionMode: settings.connectionMode,
            relayToken: settings.relayToken,
            relayAgentID: settings.relayAgentID,
            relayClientID: settings.relayClientID
        )
    }
}
