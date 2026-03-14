import Foundation

// MARK: - Gemini API Service
class GeminiService {

    static let shared = GeminiService()
    private init() {}

    // MARK: - API Key (set in Settings or Info.plist)
    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "gemini_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "gemini_api_key") }
    }

    private let model = "gemini-1.5-flash"
    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
    }

    // MARK: - Analyze Workout
    func analyzeWorkout(_ workout: Workout) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        let prompt = buildPrompt(for: workout)

        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: prompt)],
                    role: "user"
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 800,
                topP: 0.9
            )
        )

        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError("Risposta non valida")
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw GeminiError.invalidAPIKey
        }

        if httpResponse.statusCode == 429 {
            throw GeminiError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw GeminiError.networkError("HTTP \(httpResponse.statusCode): \(body)")
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }

        return text
    }

    // MARK: - Prompt Builder
    private func buildPrompt(for workout: Workout) -> String {
        """
        Sei un coach di corsa esperto e fisiologo sportivo. Analizza questo allenamento di corsa e fornisci una valutazione dettagliata in italiano.

        --- DATI ALLENAMENTO ---
        \(workout.summaryForAI)

        --- FORMATO RISPOSTA RICHIESTO ---
        Rispondi con una valutazione strutturata che includa:

        1. **Valutazione generale** (1-2 frasi, usa emoji appropriate es. ✅🔥💪⚠️)
        2. **Analisi intensità** - commenta FC media/max e zone di allenamento
        3. **Analisi passo e ritmo** - valuta la costanza del passo, eventuali negative/positive split
        4. **Punti di forza** - cosa ha funzionato bene
        5. **Aree di miglioramento** - consigli specifici e actionable
        6. **Prossimo allenamento suggerito** - proposta concreta per il prossimo workout

        Usa un tono professionale ma incoraggiante. Sii specifico con i numeri. Massimo 400 parole.
        """
    }
}

// MARK: - Errors
enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case invalidURL
    case networkError(String)
    case emptyResponse
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Inserisci la tua API key di Gemini nelle Impostazioni"
        case .invalidAPIKey:
            return "API key non valida. Verifica la chiave nelle Impostazioni"
        case .invalidURL:
            return "URL non valido"
        case .networkError(let msg):
            return "Errore di rete: \(msg)"
        case .emptyResponse:
            return "Risposta vuota da Gemini"
        case .rateLimited:
            return "Limite di richieste raggiunto. Riprova tra qualche secondo"
        }
    }
}

// MARK: - Request/Response Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
    let role: String
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
}
