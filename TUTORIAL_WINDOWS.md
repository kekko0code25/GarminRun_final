import SwiftUI

struct AddWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var title = ""
    @State private var date = Date()
    @State private var distanceText = ""
    @State private var durationMinutes = ""
    @State private var durationSeconds = ""
    @State private var avgHR = ""
    @State private var maxHR = ""
    @State private var calories = ""
    @State private var elevation = ""
    @State private var notes = ""
    @State private var laps: [LapDraft] = []
    @State private var showSuccess = false
    @State private var showLapSheet = false

    struct LapDraft: Identifiable {
        let id = UUID()
        var km: String = ""
        var min: String = ""
        var sec: String = ""
        var hr: String = ""
    }

    var canSave: Bool {
        !title.isEmpty && Double(distanceText) != nil && Int(durationMinutes) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni generali") {
                    TextField("Titolo (es. Corsa mattutina)", text: $title)
                    DatePicker("Data e ora", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "it_IT"))
                }

                Section("Prestazione") {
                    HStack {
                        Image(systemName: "road.lanes").foregroundStyle(Color("AccentGreen"))
                        TextField("Distanza (km)", text: $distanceText)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Image(systemName: "clock").foregroundStyle(Color("AccentGreen"))
                        TextField("Minuti", text: $durationMinutes)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 80)
                        Text("min")
                            .foregroundStyle(.secondary)
                        TextField("Secondi", text: $durationSeconds)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 80)
                        Text("sec")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Frequenza cardiaca") {
                    HStack {
                        Image(systemName: "heart.fill").foregroundStyle(.red)
                        TextField("FC media (bpm)", text: $avgHR)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Image(systemName: "heart.circle.fill").foregroundStyle(.pink)
                        TextField("FC massima (bpm)", text: $maxHR)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Extra") {
                    HStack {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        TextField("Calorie (kcal)", text: $calories)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Image(systemName: "mountain.2.fill").foregroundStyle(.teal)
                        TextField("Dislivello positivo (m)", text: $elevation)
                            .keyboardType(.numberPad)
                    }
                }

                // LAPS
                Section {
                    ForEach($laps) { $lap in
                        LapDraftRow(lap: $lap)
                    }
                    .onDelete { laps.remove(atOffsets: $0) }

                    Button(action: { laps.append(LapDraft()) }) {
                        Label("Aggiungi lap", systemImage: "plus.circle")
                            .foregroundStyle(Color("AccentGreen"))
                    }
                } header: {
                    Text("Lap (\(laps.count))")
                }

                Section("Note") {
                    TextField("Note libere sull'allenamento...", text: $notes, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            Label("Salva allenamento", systemImage: "checkmark.circle.fill")
                                .bold()
                                .foregroundStyle(canSave ? Color("AccentGreen") : .secondary)
                            Spacer()
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Nuovo allenamento")
            .overlay {
                if showSuccess {
                    SuccessOverlay()
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    func save() {
        guard let dist = Double(distanceText),
              let durMin = Int(durationMinutes) else { return }
        let durSec = Int(durationSeconds) ?? 0
        let totalSec = durMin * 60 + durSec
        let paceSecondsPerKm = dist > 0 ? Int(Double(totalSec) / dist) : 0

        let builtLaps: [Lap] = laps.compactMap { draft in
            guard let km = Double(draft.km),
                  let m = Int(draft.min) else { return nil }
            let s = Int(draft.sec) ?? 0
            let sec = m * 60 + s
            let pace = km > 0 ? Int(Double(sec) / km) : 0
            return Lap(
                distanceKm: km,
                durationSeconds: sec,
                avgHeartRate: Int(draft.hr) ?? 0,
                avgPaceSecondsPerKm: pace
            )
        }

        let workout = Workout(
            date: date,
            title: title,
            distanceKm: dist,
            durationSeconds: totalSec,
            avgHeartRate: Int(avgHR) ?? 0,
            maxHeartRate: Int(maxHR) ?? 0,
            avgPaceSecondsPerKm: paceSecondsPerKm,
            calories: Int(calories) ?? 0,
            elevationGainM: Int(elevation) ?? 0,
            laps: builtLaps,
            notes: notes
        )

        store.add(workout)
        resetForm()

        withAnimation(.spring(duration: 0.4)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { showSuccess = false }
        }
    }

    func resetForm() {
        title = ""
        distanceText = ""
        durationMinutes = ""
        durationSeconds = ""
        avgHR = ""
        maxHR = ""
        calories = ""
        elevation = ""
        notes = ""
        laps = []
        date = Date()
    }
}

// MARK: - Lap Draft Row
struct LapDraftRow: View {
    @Binding var lap: AddWorkoutView.LapDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundStyle(Color("AccentGreen"))
                    .font(.caption)
                TextField("Km", text: $lap.km)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: 55)
                Text("km")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                TextField("Min", text: $lap.min)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 40)
                Text(":")
                    .foregroundStyle(.secondary)
                TextField("Sec", text: $lap.sec)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 40)
                Spacer()
                TextField("FC", text: $lap.hr)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 45)
                Text("bpm")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Success Overlay
struct SuccessOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color("AccentGreen"))
                Text("Allenamento salvato!")
                    .font(.title3.bold())
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}
