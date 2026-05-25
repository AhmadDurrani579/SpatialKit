struct ChatInputView: View {
    
    @Binding var question: String
    @Binding var answer: String
    @Binding var isAsking: Bool
    let onSubmit: (String) -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            if !answer.isEmpty {
                Text(answer)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
            }
            
            HStack(spacing: 8) {
                TextField("Ask about this space...", text: $question)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .accentColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)
                    .submitLabel(.send)
                    .onSubmit {
                        submit()
                    }
                
                Button { submit() } label: {
                    Image(systemName: isAsking
                          ? "ellipsis.circle.fill"
                          : "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                }
                .disabled(isAsking || question.isEmpty)
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 50)
    }
    
    private func submit() {
        guard !question.isEmpty && !isAsking else { return }
        onSubmit(question)
        question = ""
    }
}