import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    LabeledContent("Relay URL") {
                        TextField("https://tarsrelay.pqcenter.cn", text: $settings.relayBaseURLString)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("Session ID") {
                        TextField("mobile-main", text: $settings.sessionID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                    }
                }

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

                Section("Notes") {
                    Text("The iOS app connects through Tars Relay only. Local Tars must run with matching mobile relay settings.")
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
