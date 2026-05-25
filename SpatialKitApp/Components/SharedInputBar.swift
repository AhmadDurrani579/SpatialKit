import SwiftUI
import SpatialKit
import Speech

struct SharedInputBar: View {
    
    @ObservedObject var sdk: SpatialKitSDK
    @Binding var appState: MainView.AppState
    
    @State private var question:     String = ""
    @State private var isListening:  Bool   = false
    @State private var isAsking:     Bool   = false
    @State private var useTextInput: Bool   = false
    @State private var lastPartial:  String = ""
    @FocusState private var focused: Bool
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine      = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask:    SFSpeechRecognitionTask?
    
    var body: some View {
        HStack(spacing: 12) {
            
            // mic button
            Button {
                if useTextInput {
                    useTextInput = false
                } else if isListening {
                    stopListening()
                } else {
                    startListening()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(isListening ? 0.3 : 0.15))
                    Circle()
                        .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
                    Image(systemName: isListening ? "waveform" : "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                }
                .frame(width: 48, height: 48)
            }
            
            // text input
            HStack {
                TextField(
                    isAsking    ? "thinking..."  :
                    isListening ? "listening..." :
                                  "tap mic or type to ask...",
                    text: $question
                )
                .font(.system(size: 14))
                .foregroundColor(.white)
                .accentColor(.green)
                .focused($focused)
                .submitLabel(.send)
                .disabled(isAsking)
                .onSubmit { submitText() }
                .onTapGesture { useTextInput = true }
                
                if !question.isEmpty && !isAsking {
                    Button { submitText() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(focused ? 0.3 : 0.12),
                            lineWidth: 1)
            )
            .cornerRadius(24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Submit
    private func submitText() {
        guard !question.isEmpty && !isAsking else { return }
        let text = question
        question = ""
        focused  = false
        submit(text)
    }
    
    private func submit(_ text: String) {
        isAsking = true
        withAnimation { appState = .agent }
        
        Task {
            let response = await sdk.ask(text)
            await MainActor.run {
                isAsking = false
                NotificationCenter.default.post(
                    name: .spatialKitAgentResponse,
                    object: nil,
                    userInfo: ["question": text, "answer": response]
                )
            }
            DispatchQueue.main.async {
                speak(response)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    // MARK: - Voice
    private func startListening() {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
            DispatchQueue.main.async { beginListening() }
        }
    }
    
    private func beginListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord,
                                  mode: .default,
                                  options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest
        ) { result, error in
            if let result = result {
                lastPartial = result.bestTranscription.formattedString
                if result.isFinal {
                    stopListening()
                    submit(lastPartial)
                }
            }
            if error != nil {
                let heard = lastPartial
                stopListening()
                if !heard.isEmpty { submit(heard) }
            }
        }
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            guard buffer.frameLength > 0 else { return }
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isListening = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isListening { stopListening() }
        }
    }
    
    private func stopListening() {
        isListening = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask =