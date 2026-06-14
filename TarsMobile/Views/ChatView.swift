import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var viewModel: ChatViewModel
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                connectionStrip
                messageList
                composer
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tars")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.reconnect()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Reconnect")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
                    .environmentObject(settings)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var connectionStrip: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(viewModel.activityText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            Text(settings.sessionID)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("Relay")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages) { _, messages in
                guard let last = messages.last else {
                    return
                }

                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message Tars", text: $viewModel.draft, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button {
                viewModel.sendDraft()
            } label: {
                Image(systemName: viewModel.isSending ? "hourglass" : "paperplane.fill")
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(12)
        .background(.bar)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 36)
            }

            VStack(alignment: .leading, spacing: 6) {
                MarkdownChartView(markdown: message.content)

                if message.isStreaming {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)

            if !message.isFromUser {
                Spacer(minLength: 36)
            }
        }
        .padding(.horizontal, 16)
    }

    private var background: Color {
        if message.isFromUser {
            return Color.accentColor.opacity(0.14)
        }

        return Color(.secondarySystemGroupedBackground)
    }

}
