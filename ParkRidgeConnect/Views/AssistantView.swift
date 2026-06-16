import SwiftUI

struct AssistantView: View {
    @Environment(TownStore.self) private var store
    @Environment(VoiceController.self) private var voice
    @State private var draft = ""

    private var prompts: [String] {
        store.config.assistantSuggestedPrompts
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
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
                    .background { TownBackdrop() }
                    .onChange(of: store.messages.count) {
                        if let last = store.messages.last?.id {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }

                composer
            }
            .navigationTitle("Ask \(store.config.townName)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: submitQueuedPromptIfNeeded)
        }
    }

    private var promptRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        submit(prompt)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PRTheme.teal)
                                .padding(.top, 1)
                            Text(prompt)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(PRTheme.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(width: 168, alignment: .topLeading)
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(PRTheme.paper)
                                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(PRTheme.line, lineWidth: 1)
                        }
                    }
                    .buttonStyle(PRPressableStyle())
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
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
            HStack(spacing: 10) {
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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background {
                            Circle()
                                .fill(voice.isRecording ? PRTheme.cranberry : PRTheme.teal)
                                .shadow(color: (voice.isRecording ? PRTheme.cranberry : PRTheme.teal).opacity(0.30), radius: 6, y: 3)
                        }
                }
                .buttonStyle(PRPressableStyle())
                .accessibilityLabel(voice.isRecording ? "Stop voice input" : "Start voice input")

                HStack(spacing: 8) {
                    TextField("Ask about \(store.config.townName)...", text: $draft, axis: .vertical)
                        .lineLimit(1...4)
                        .font(.subheadline)
                        .textFieldStyle(.plain)

                    Button {
                        submit(draft)
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(
                                draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? AnyShapeStyle(PRTheme.muted.opacity(0.35))
                                    : AnyShapeStyle(PRTheme.teal),
                                in: Circle()
                            )
                    }
                    .buttonStyle(PRPressableStyle())
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Send message")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(PRTheme.paper, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(PRTheme.line, lineWidth: 1)
                }
            }

            HStack {
                Label(voice.statusText, systemImage: "speaker.wave.2")
                    .font(.caption)
                    .foregroundStyle(PRTheme.muted)
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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

    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: isUser ? 20 : 6,
            bottomTrailingRadius: isUser ? 6 : 20,
            topTrailingRadius: 20,
            style: .continuous
        )
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 8) {
                Text(message.text)
                    .font(.subheadline)
                    .lineSpacing(3)
                    .foregroundStyle(isUser ? .white : PRTheme.ink)
                    .textSelection(.enabled)

                if !message.relatedSourceTitles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(message.relatedSourceTitles, id: \.self) { title in
                                SourceBadge(title: title)
                            }
                        }
                    }
                }

                if !isUser {
                    Button(action: speak) {
                        Label("Read", systemImage: "speaker.wave.2.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PRTheme.teal)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(PRTheme.teal.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(PRPressableStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                if isUser {
                    bubbleShape
                        .fill(PRTheme.brandGradient)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
                } else {
                    bubbleShape
                        .fill(PRTheme.paper)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
                }
            }
            .overlay {
                if !isUser {
                    bubbleShape.strokeBorder(PRTheme.line, lineWidth: 1)
                }
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }
}
