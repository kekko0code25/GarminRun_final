import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = GeminiService.shared.apiKey
    @State private var isKeyVisible = false
    @State private var isTesting = false
    @State private var testResult: TestResult?

    enum TestResult {
        case success(String)
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Device section
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AccentGreen").opacity(0.15))
                                .frame(width: 48, height: 48)
                            Image(systemName: "applewatch")
                                .font(.title2)
                                .foregroundStyle(Color("AccentGreen"))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Garmin Forerunner 255")
                                .font(.subheadline.bold())
                            Text("Inserisci manualmente i dati o sincronizza via Garmin Connect")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Dispositivo")
                }

                // Gemini AI
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                            Text("Google Gemini API Key")
                                .font(.subheadline.bold())
                        }

                        Text("Ottieni la tua API key gratuita su aistudio.google.com")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Group {
                                if isKeyVisible {
                                    TextField("AIzaSy...", text: $apiKey)
                                } else {
                                    SecureField("AIzaSy...", text: $apiKey)
                                }
                            }
                            .font(.system(.subheadline, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            Button {
                                isKeyVisible.toggle()
                            } label: {
                                Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Status
                        HStack {
                            Circle()
                                .fill(apiKey.isEmpty ? .red : Color("AccentGreen"))
                                .frame(width: 8, height: 8)
                            Text(apiKey.isEmpty ? "API key non configurata" : "API key configurata ✓")
                                .font(.caption)
                                .foregroundStyle(apiKey.isEmpty ? .red : Color("AccentGreen"))
                        }

                        // Test result
                        if let result = testResult {
                            Group {
                                switch result {
                                case .success(let msg):
                                    Label(msg, systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                case .failure(let msg):
                                    Label(msg, systemImage: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .font(.caption)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                (testResult.map { if case .success = $0 { return true }; return false } ?? false)
                                    ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        HStack(spacing: 10) {
                            Button(action: saveKey) {
                                Text("Salva")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color("AccentGreen"))
                                    .foregroundStyle(.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)

                            Button(action: testKey) {
                                HStack {
                                    if isTesting {
                                        ProgressView().tint(.white)
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Testa")
                                    }
                                }
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.purple)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .disabled(apiKey.isEmpty || isTesting)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Intelligenza artificiale")
                } footer: {
                    Text("La chiave viene salvata localmente sul dispositivo e non viene mai condivisa.")
                }

                // How to get API key
                Section {
                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(.blue)
                            Text("Ottieni API key su AI Studio")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Come ottenere la API key:")
                            .font(.caption.bold())
                        VStack(alignment: .leading, spacing: 4) {
                            StepRow(n: "1", text: "Vai su aistudio.google.com")
                            StepRow(n: "2", text: "Accedi con il tuo account Google")
                            StepRow(n: "3", text: "Clicca su \"Get API key\" → \"Create API key\"")
                            StepRow(n: "4", text: "Copia la chiave e incollala qui sopra")
                            StepRow(n: "5", text: "Il tier gratuito offre 1500 richieste/giorno")
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Guida configurazione")
                }

                // App info
                Section {
                    HStack {
                        Text("Versione")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Allenamenti salvati")
                        Spacer()
                        WorkoutCountBadge()
                    }
                } header: {
                    Text("App")
                }
            }
            .navigationTitle("Impostazioni")
        }
    }

    func saveKey() {
        GeminiService.shared.apiKey = apiKey
        testResult = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func testKey() {
        saveKey()
        isTesting = true
        testResult = nil

        let dummyWorkout = Workout(
            date: Date(),
            title: "Test corsa",
            distanceKm: 5.0,
            durationSeconds: 1500,
            avgHeartRate: 145,
            maxHeartRate: 168,
            avgPaceSecondsPerKm: 300,
            calories: 380,
            elevationGainM: 20,
            laps: [],
            notes: ""
        )

        Task {
            do {
                _ = try await GeminiService.shared.analyzeWorkout(dummyWorkout)
                await MainActor.run {
                    testResult = .success("Connessione a Gemini riuscita! ✓")
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = .failure(error.localizedDescription)
                    isTesting = false
                }
            }
        }
    }
}

struct StepRow: View {
    let n: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(n + ".")
                .font(.caption)
                .foregroundStyle(Color("AccentGreen"))
                .frame(width: 14, alignment: .trailing)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct WorkoutCountBadge: View {
    @EnvironmentObject var store: WorkoutStore

    var body: some View {
        Text("\(store.workouts.count)")
            .foregroundStyle(.secondary)
    }
}
