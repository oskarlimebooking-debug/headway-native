import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()
    let showToast: (String, ToastType) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgSurface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Gemini AI
                        SettingsSection(title: "Gemini AI", icon: "brain") {
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("API Key")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                    SecureField("Enter your Gemini API key", text: $viewModel.geminiApiKey)
                                        .settingsInput()
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Model")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                    Picker("Model", selection: $viewModel.selectedModel) {
                                        ForEach(Constants.availableModels, id: \.self) { model in
                                            Text(model).tag(model)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .settingsInput()
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Image Model")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                    Picker("Image Model", selection: $viewModel.selectedImageModel) {
                                        ForEach(Constants.imageModels, id: \.self) { model in
                                            Text(model).tag(model)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .settingsInput()
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reading Speed (WPM)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                    TextField("200", text: $viewModel.readingSpeed)
                                        .keyboardType(.numberPad)
                                        .settingsInput()
                                }
                            }
                        }

                        // MARK: - TTS Provider
                        SettingsSection(title: "Text-to-Speech", icon: "speaker.wave.2") {
                            VStack(spacing: 12) {
                                Picker("Provider", selection: $viewModel.ttsProvider) {
                                    Text("Native (Device)").tag("native")
                                    Text("Lazybird API").tag("lazybird")
                                    Text("Google Cloud TTS").tag("google")
                                }
                                .pickerStyle(.segmented)

                                // Lazybird settings
                                if viewModel.ttsProvider == "lazybird" {
                                    VStack(spacing: 12) {
                                        SecureField("Lazybird API Key", text: $viewModel.lazybirdApiKey)
                                            .settingsInput()

                                        Button("Fetch Voices") {
                                            Task { await viewModel.fetchLazybirdVoices() }
                                        }
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.accent)

                                        if !viewModel.lazybirdVoices.isEmpty {
                                            Picker("Voice", selection: $viewModel.lazybirdVoiceId) {
                                                Text("Select a voice").tag("")
                                                ForEach(viewModel.lazybirdVoices) { voice in
                                                    Text(voice.displayName).tag(voice.id)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .settingsInput()
                                        }
                                    }
                                }

                                // Google TTS settings
                                if viewModel.ttsProvider == "google" {
                                    VStack(spacing: 12) {
                                        SecureField("Google Cloud TTS API Key", text: $viewModel.googleTTSApiKey)
                                            .settingsInput()

                                        Button("Fetch Voices") {
                                            Task { await viewModel.fetchGoogleTTSVoices() }
                                        }
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.accent)

                                        if !viewModel.googleTTSVoices.isEmpty {
                                            Picker("Language", selection: $viewModel.googleTTSLanguage) {
                                                let languages = Set(viewModel.googleTTSVoices.flatMap { $0.languageCodes }).sorted()
                                                ForEach(languages, id: \.self) { lang in
                                                    Text(lang).tag(lang)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .settingsInput()

                                            Picker("Voice", selection: $viewModel.googleTTSVoice) {
                                                Text("Select a voice").tag("")
                                                let filtered = viewModel.googleTTSVoices.filter { $0.languageCodes.contains(viewModel.googleTTSLanguage) }
                                                ForEach(filtered) { voice in
                                                    Text(voice.displayName).tag(voice.name)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .settingsInput()
                                        }
                                    }
                                }
                            }
                        }

                        // MARK: - Google Drive Sync
                        SettingsSection(title: "Google Drive Sync", icon: "icloud") {
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Google OAuth Client ID")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                    TextField("Enter Client ID", text: $viewModel.googleClientId)
                                        .settingsInput()
                                }

                                HStack {
                                    Circle()
                                        .fill(viewModel.isSyncConnected ? Theme.success : Theme.textMuted)
                                        .frame(width: 8, height: 8)
                                    Text(viewModel.isSyncConnected ? "Connected" : "Not connected")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textSecondary)
                                    Spacer()
                                    if let lastSync = viewModel.lastSyncTime {
                                        Text("Last: \(lastSync)")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.textMuted)
                                    }
                                }

                                HStack(spacing: 12) {
                                    Button(action: {
                                        Task {
                                            do {
                                                try await GoogleDriveService.shared.authenticate(clientId: viewModel.googleClientId)
                                                viewModel.isSyncConnected = true
                                                showToast("Connected to Google Drive!", .success)
                                            } catch {
                                                showToast("Connection failed: \(error.localizedDescription)", .error)
                                            }
                                        }
                                    }) {
                                        Text(viewModel.isSyncConnected ? "Reconnect" : "Connect")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Theme.accentGradient)
                                            .cornerRadius(Theme.radiusSm)
                                    }

                                    if viewModel.isSyncConnected {
                                        Button(action: {
                                            Task {
                                                viewModel.isSyncing = true
                                                do {
                                                    try await GoogleDriveService.shared.syncNow(context: modelContext)
                                                    showToast("Sync complete!", .success)
                                                } catch {
                                                    showToast("Sync failed: \(error.localizedDescription)", .error)
                                                }
                                                viewModel.isSyncing = false
                                            }
                                        }) {
                                            HStack {
                                                if viewModel.isSyncing {
                                                    ProgressView().tint(.white)
                                                }
                                                Text("Sync Now")
                                            }
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Theme.success)
                                            .cornerRadius(Theme.radiusSm)
                                        }
                                        .disabled(viewModel.isSyncing)
                                    }
                                }
                            }
                        }

                        // MARK: - Data
                        SettingsSection(title: "Data", icon: "externaldrive") {
                            VStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        do {
                                            let data = try await DataExportService.shared.exportAll(context: modelContext)
                                            let url = FileManager.default.temporaryDirectory.appendingPathComponent("chapterwise-backup.json")
                                            try data.write(to: url)
                                            // Share
                                            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                               let rootVC = windowScene.windows.first?.rootViewController {
                                                rootVC.present(activityVC, animated: true)
                                            }
                                        } catch {
                                            showToast("Export failed: \(error.localizedDescription)", .error)
                                        }
                                    }
                                }) {
                                    Label("Export All Data", systemImage: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Theme.accentSoft)
                                        .cornerRadius(Theme.radiusSm)
                                }
                            }
                        }

                        // MARK: - About
                        SettingsSection(title: "About", icon: "info.circle") {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("ChapterWise")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text("v1.0.0")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textMuted)
                                }
                                Text("Personal reading app — read a chapter every day. Learn something new.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveSettings(context: modelContext)
                        showToast("Settings saved!", .success)
                        dismiss()
                    }
                    .foregroundColor(Theme.accent)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                viewModel.loadSettings(context: modelContext)
            }
        }
    }
}

// MARK: - Section Component
private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            content
        }
        .padding(20)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Input Modifier
extension View {
    func settingsInput() -> some View {
        self
            .font(.system(size: 14))
            .padding(12)
            .background(Theme.bgElevated)
            .foregroundColor(Theme.textPrimary)
            .cornerRadius(Theme.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSm)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}
