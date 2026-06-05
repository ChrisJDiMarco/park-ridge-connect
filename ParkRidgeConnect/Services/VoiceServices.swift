import AVFoundation
import Foundation
import Speech

enum VoiceError: Error {
    case unavailable
}

@MainActor
@Observable
final class VoiceController {
    var transcript = ""
    var isRecording = false
    var statusText = "Voice ready"

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioPlayer: AVAudioPlayer?
    private let elevenLabs = ElevenLabsVoiceService()

    func requestPermissions() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        let micAllowed = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }

        statusText = speechAllowed && micAllowed ? "Voice ready" : "Enable microphone and speech permissions in Settings"
        return speechAllowed && micAllowed
    }

    func startRecording() async {
        guard await requestPermissions(), let recognizer, recognizer.isAvailable else {
            statusText = "Speech recognition is unavailable"
            return
        }

        stopRecording()
        transcript = ""

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
                request?.append(buffer)
            }

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result {
                        self?.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil || result?.isFinal == true {
                        self?.stopRecording()
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            statusText = "Listening..."
        } catch {
            statusText = "Could not start voice input"
            stopRecording()
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        if !transcript.isEmpty {
            statusText = "Captured voice prompt"
        }
    }

    func speak(_ text: String) async {
        if let data = try? await elevenLabs.audioData(for: text) {
            do {
                audioPlayer = try AVAudioPlayer(data: data)
                audioPlayer?.play()
                statusText = "Speaking with ElevenLabs"
                return
            } catch {
                statusText = "ElevenLabs audio failed, using Apple voice"
            }
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.49
        synthesizer.speak(utterance)
        statusText = "Speaking with Apple voice"
    }
}

struct ElevenLabsVoiceService {
    private var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String
    }

    private var voiceID: String {
        (Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_VOICE_ID") as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "JBFqnCBsd6RMkjVDRZzb"
    }

    func audioData(for text: String) async throws -> Data? {
        guard let apiKey, !apiKey.isEmpty else { return nil }
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)/stream")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "text": String(text.prefix(900)),
            "model_id": "eleven_flash_v2_5",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw VoiceError.unavailable
        }
        return data
    }
}

