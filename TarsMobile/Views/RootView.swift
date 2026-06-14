import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        ChatView(viewModel: viewModel)
            .onAppear {
                viewModel.configure(
                    baseURL: settings.serverBaseURL,
                    sessionID: settings.sessionID
                )
            }
            .onChange(of: settings.serverBaseURLString) { _, _ in
                viewModel.configure(
                    baseURL: settings.serverBaseURL,
                    sessionID: settings.sessionID
                )
            }
            .onChange(of: settings.sessionID) { _, newValue in
                viewModel.configure(
                    baseURL: settings.serverBaseURL,
                    sessionID: newValue
                )
            }
    }
}

