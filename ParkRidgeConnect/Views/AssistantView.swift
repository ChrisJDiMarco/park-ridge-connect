import SwiftUI

struct AssistantView: View {
    @Environment(TownStore.self) private var store
    @Environment(VoiceController.self) private var voice
    @State private var draft = ""

    private let prompts = [
        "What is happening in town this week?",
        "Where should I take kids after school?",
        "Best dinner or drinks tonight?",
        "How do I handle trash, water, or permits?",
        "How do I commute to NYC?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            promptRail
                            ForEach(store.messages) { message in
                                MessageBubble(message: message) {
                                    Task { await voice.speak(message.text) }
                                }
                                .id(message.id)
                            }

                            if voice.isRecording {
                                listeningCard
                            }
                        }
                        .padding(16)
                    }
                    .background(PRTheme.canvas)
                    .onChange(of: store.messages.count) {
                        if let last = store.messages.last?.id {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }

                composer
            }
            .navigationTitle("Ask Park Ridge")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: submitQueuedPromptIfNeeded)
        }
    }

    private var promptRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        submit(prompt)
                    } label: {
                        Text(prompt)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(width: 150, alignment: .leading)
                            .padding(10)
                            .background(PRTheme.paper, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var listeningCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(voice.statusText, systemImage: "waveform")
                .font(.headline)
                .foregroundStyle(PRTheme.teal)
            Text(voice.transcript.isEmpty ? "Listening..." : voice.transcript)
                .font(.subheadline)
                .foregroundStyle(PRTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    private var composer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    Task {
                        if voice.isRecording {
                            voice.stopRecording()
                            draft = voice.transcript
                        } else {
                            await voice.startRecording()
                        }
                    }
                } label: {
                    Image(systemName: voice.isRecording ? "stop.fill" : "mic.fill")
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.borderedProminent)
                .tint(voice.isRecording ? PRTheme.cranberry : PRTheme.teal)
                .accessibilityLabel(voice.isRecording ? "Stop voice input" : "Start voice input")

                TextField("Ask about Park Ridge...", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)

                Button {
                    submit(draft)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Send message")
            }

            HStack {
                Label(voice.statusText, systemImage: "speaker.wave.2")
                    .font(.caption)
                    .foregroundStyle(PRTheme.muted)
                Spacer()
            }
        }
        .padding(12)
        .background(.regularMaterial)
    }

    private func submit(_ text: String) {
        let reply = store.send(text)
        draft = ""
        Task { await voice.speak(reply.text) }
    }

    private func submitQueuedPromptIfNeeded() {
        guard let prompt = store.consumeQueuedAssistantPrompt() else { return }
        submit(prompt)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let speak: () -> Void

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 32) }
            VStack(alignment: .leading, spacing: 8) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(isUser ? .white : PRTheme.ink)
                    .textSelection(.enabled)

                if !message.relatedSourceTitles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(message.relatedSourceTitles, id: \.self) { title in
                                SourceBadge(title: title)
                            }
                        }
                    }
                }

                if !isUser {
                    Button(action: speak) {
                        Label("Read", systemImage: "speaker.wave.2.fill")
                            .font(.caption.weight(.bold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
            .padding(12)
            .background(isUser ? PRTheme.teal : PRTheme.paper, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isUser ? Color.clear : PRTheme.line, lineWidth: 1)
            }
            if !isUser { Spacer(minLength: 32) }
        }
    }
}
