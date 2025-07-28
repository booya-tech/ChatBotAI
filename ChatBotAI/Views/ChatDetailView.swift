//
//  ChatDetailView.swift
//  ChatBotAI
//
//  Chat interface for a specific conversation
//

import SwiftUI

struct ChatDetailView: View {
    @State var conversation: ChatConversation // Changed to @State so we can update it
    
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var aiService = AIService.shared
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var showAPITestResult = false
    @State private var apiTestMessage = ""
    @State private var isGeneratingTitle = false
    
    // Titles that should be auto-replaced with AI-generated ones
    private let genericTitles = [
        "New Chat", "General Chat", "Creative Writing", "Code Help",
        "Learning & Study", "Problem Solving", "Brainstorming"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else {
                chatView
            }
        }
        .navigationTitle(isGeneratingTitle ? "Generating title..." : conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Test APIs") {
                    Task {
                        await testAllAPIs()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                AIModelSelectorView(aiService: aiService)
                    .zIndex(1001)
            }
        }
        .task {
            await loadMessages()
        }
        .alert("API Status Test", isPresented: $showAPITestResult) {
            Button("OK") { showAPITestResult = false }
        } message: {
            Text(apiTestMessage)
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading messages...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var chatView: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        TypingIndicatorView(isTyping: isSending || aiService.isGenerating)
                            .id("loading")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .onTapGesture {
                    // Dismiss keyboard when tapping on messages
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isSending) { _ in
                    if isSending || aiService.isGenerating {
                        scrollToBottom(proxy: proxy, anchor: .bottom)
                    }
                }
                .onChange(of: aiService.isGenerating) { _ in
                    if aiService.isGenerating {
                        scrollToBottom(proxy: proxy, anchor: .bottom)
                    }
                }
            }
            
            // Error Banners
            if let error = supabaseService.error {
                ErrorBannerView(error: error) {
                    supabaseService.error = nil
                }
            }
            
            if let aiError = aiService.error {
                ErrorBannerView(error: SupabaseError.databaseError(aiError.localizedDescription)) {
                    aiService.error = nil
                }
            }
            
            // Input Field
            ChatInputView(
                inputText: $inputText,
                isSending: isSending || aiService.isGenerating,
                onSend: sendMessage
            )
        }
    }
    
    // MARK: - Data Loading
    
    private func loadMessages() async {
        isLoading = true
        
        do {
            let chatMessages = try await supabaseService.fetchMessages(for: conversation.id)
            await MainActor.run {
                messages = chatMessages.map { Message(from: $0) }
                isLoading = false
            }
        } catch {
            print("❌ Failed to load messages: \(error)")
            await MainActor.run {
                supabaseService.error = .databaseError("Failed to load messages")
                isLoading = false
            }
        }
    }
    
    // MARK: - Message Sending
    
    private func sendMessage() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        let messageContent = trimmedInput
        inputText = ""
        isSending = true
        
        Task {
            // Step 1: Send user message
            do {
                let userMessage = try await supabaseService.sendMessage(
                    conversationId: conversation.id,
                    content: messageContent
                )
                
                await MainActor.run {
                    let localUserMessage = Message(from: userMessage)
                    messages.append(localUserMessage)
                }
                
                print("✅ User message sent successfully")
                
                // Step 1.5: Auto-generate title if this is the first user message and has generic title
                if shouldGenerateTitle(for: messageContent) {
                    await generateAndUpdateTitle(from: messageContent)
                }
                
            } catch {
                print("❌ Failed to send user message: \(error)")
                await MainActor.run {
                    supabaseService.error = .databaseError("Failed to send message")
                    isSending = false
                    inputText = messageContent // Restore input
                }
                return
            }
            
            // Step 2: Generate AI response
            do {
                let aiResponseContent = try await aiService.generateResponse(
                    for: messageContent,
                    conversationHistory: messages
                )
                
                let aiMessage = try await supabaseService.sendAIResponse(
                    conversationId: conversation.id,
                    content: aiResponseContent
                )
                
                await MainActor.run {
                    let localAIMessage = Message(from: aiMessage)
                    messages.append(localAIMessage)
                }
                
                print("✅ AI response generated successfully")
                
            } catch {
                print("❌ Failed to generate AI response: \(error)")
                
                // Auto-fallback to Mock AI if model fails
                if error.localizedDescription.contains("Model not found") {
                    print("🔄 Auto-switching to Mock AI due to model unavailability")
                    aiService.switchModel(to: .mockAI)
                    
                    let mockProvider = MockAIProvider()
                    let mockResponse = try await mockProvider.generateResponse(for: messageContent, conversationHistory: messages)
                    
                    do {
                        let aiMessage = try await supabaseService.sendAIResponse(
                            conversationId: conversation.id,
                            content: mockResponse
                        )
                        
                        await MainActor.run {
                            let localAIMessage = Message(from: aiMessage)
                            messages.append(localAIMessage)
                        }
                        print("✅ Fallback response sent successfully")
                    } catch {
                        print("❌ Even fallback failed: \(error)")
                    }
                } else {
                    await MainActor.run {
                        if let aiError = error as? AIError {
                            aiService.error = aiError
                        } else {
                            aiService.error = .generationFailed(error.localizedDescription)
                        }
                    }
                }
            }
            
            await MainActor.run {
                isSending = false
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isSending || aiService.isGenerating {
                proxy.scrollTo("loading", anchor: anchor)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: anchor)
            }
        }
    }
    
    private func testAllAPIs() async {
        print("🧪 Testing all API tokens...")
        
        var results: [String] = []
        
        // Test Groq
        let groqResult = await AIConfig.testGroqToken()
        if groqResult.isValid {
            results.append("✅ Groq: Working")
        } else {
            results.append("❌ Groq: \(groqResult.error ?? "Failed")")
        }
        
        await MainActor.run {
            apiTestMessage = results.joined(separator: "\n\n")
            showAPITestResult = true
            
            // Auto-switch to working AI if current one fails
            if !groqResult.isValid {
                print("🔄 Auto-switching to Mock AI since Groq failed")
                aiService.switchModel(to: .mockAI)
            }
        }
    }
    
    // MARK: - Auto-Title Generation
    
    private func shouldGenerateTitle(for message: String) -> Bool {
        // Only generate title if:
        // 1. This is the first user message (only has welcome AI message + this new one)
        // 2. Current title is one of the generic ones
        // 3. Message is meaningful (not just "hi" or "hello")
        
        let userMessages = messages.filter { $0.isFromUser }
        let isFirstUserMessage = userMessages.count == 1 // Only the one we just added
        
        let hasGenericTitle = genericTitles.contains(conversation.title)
        
        let meaningfulMessage = message.trimmingCharacters(in: .whitespacesAndNewlines).count > 5
        
        print("🔍 Title generation check:")
        print("  - User messages count: \(userMessages.count)")
        print("  - Is first message: \(isFirstUserMessage)")
        print("  - Has generic title: \(hasGenericTitle) (\(conversation.title))")
        print("  - Meaningful message: \(meaningfulMessage)")
        
        return isFirstUserMessage && hasGenericTitle && meaningfulMessage
    }
    
    private func generateAndUpdateTitle(from message: String) async {
        guard !isGeneratingTitle else { return }
        
        await MainActor.run {
            isGeneratingTitle = true
        }
        
        do {
            print("🏷️ Generating title from message: \(message)")
            
            let newTitle = try await aiService.generateConversationTitle(from: message)
            
            // Update in database
            try await supabaseService.updateConversationTitle(
                conversationId: conversation.id,
                title: newTitle
            )
            
            // Update local conversation object
            await MainActor.run {
                conversation = ChatConversation(
                    id: conversation.id,
                    userId: conversation.userId,
                    title: newTitle,
                    createdAt: conversation.createdAt,
                    updatedAt: Date()
                )
                isGeneratingTitle = false
                
                // Notify conversation list to refresh
                NotificationCenter.default.post(name: .conversationTitleUpdated, object: nil)
                
                print("✅ Title updated to: \(newTitle)")
            }
            
        } catch {
            print("❌ Failed to generate title: \(error)")
            await MainActor.run {
                isGeneratingTitle = false
            }
            // Don't show error to user - title generation is a nice-to-have feature
        }
    }
}

#Preview {
    @State var sampleConversation = ChatConversation(
        id: UUID(),
        userId: "sample-user",
        title: "Sample Chat",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    NavigationView {
        ChatDetailView(conversation: sampleConversation)
    }
} 