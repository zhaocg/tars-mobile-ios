import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    Picker("Mode", selection: $settings.connectionModeRaw) {
                        ForEach(TarsConnectionMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }

                    if settings.connectionMode == .relay {
                        LabeledContent("Relay URL") {
                            TextField("https://tarsrelay.pqcenter.cn", text: $settings.relayBaseURLString)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        LabeledContent("Server URL") {
                            TextField("http://127.0.0.1:18991", text: $settings.directBaseURLString)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    LabeledContent("Session ID") {
                        TextField("mobile-main", text: $settings.sessionID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                    }
                }

                if settings.connectionMode == .relay {
                    Section("Relay") {
                        LabeledContent("Relay Token") {
                            SecureField("Bearer token", text: $settings.relayToken)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .multilineTextAlignment(.trailing)
                        }

                        LabeledContent("Agent ID") {
                            TextField("default", text: $settings.relayAgentID)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .multilineTextAlignment(.trailing)
                        }

                        LabeledContent("Client ID") {
                            TextField("ios-device", text: $settings.relayClientID)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                Section("Notes") {
                    Text(settings.connectionMode == .relay
                         ? "Use Relay when the iPhone and Tars are not on the same network."
                         : "Use the Mac or server LAN IP when running on a physical iPhone.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
