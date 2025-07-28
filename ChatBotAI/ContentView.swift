//
//  ContentView.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import SwiftUI

// MARK: - Service Type Alias
// Change this to SupabaseService once package is linked properly
typealias ChatService = SupabaseService

// MARK: - Chat View
struct ContentView: View {
    @StateObject private var supabaseService = ChatService.shared
    @StateObject private var aiService = AIService.shared
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var currentConversation: ChatConversation?
    @State private var isInitializing = true
    @State private var isSending = false
    @State private var showAPITestResult = false
    @State private var apiTestMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isInitializing {
                    // Loading State
                    VStack {
                        Spacer()
                        ProgressView("Setting up your chat...")
                            .font(.headline)
                        Spacer()
                    }
                } else {
                    chatView
                }
            }
            .navigationTitle("ChatBot AI")
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
                        .zIndex(1001) // Ensure toolbar item is above other content
                }
            }
            .task {
                await initializeChat()
            }
            .alert("API Status Test", isPresented: $showAPITestResult) {
                Button("OK") { showAPITestResult = false }
            } message: {
                Text(apiTestMessage)
            }
        }
    }
    
    // MARK: - Computed Views
    
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
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .onTapGesture {
                    // Dismiss keyboard when tapping on the messages area
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
            
            // Error Banner
            if let error = supabaseService.error {
                ErrorBannerView(error: error) {
                    supabaseService.error = nil
                }
            }
            
            // AI Error Banner
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
    
    // MARK: - Actions
    
    private func initializeChat() async {
        do {
            print("🚀 Starting chat initialization...")
            
            // Sign in anonymously if not already signed in
            if !supabaseService.isSignedIn {
                print("👤 User not signed in, attempting anonymous sign in...")
                try await supabaseService.signInAnonymously()
            } else {
                print("👤 User already signed in")
            }
            
            // Add a small delay to ensure authentication is complete
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            print("📂 Fetching user conversations...")
            // Try to get existing conversations or create a new one
            let conversations = try await supabaseService.fetchUserConversations()
            print("📂 Found \(conversations.count) conversations")
            
            if let existingConversation = conversations.first {
                print("📖 Using existing conversation: \(existingConversation.id)")
                currentConversation = existingConversation
                await loadMessages(for: existingConversation.id)
            } else {
                print("➕ Creating new conversation...")
                // Create a new conversation
                let newConversation = try await supabaseService.createConversation(title: "New Chat")
                currentConversation = newConversation
                
                print("💬 Adding welcome message...")
                // Generate welcome message using AI
                let welcomeMessage = try await aiService.generateResponse(
                    for: "Please introduce yourself as a helpful AI assistant and ask how you can help."
                )
                
                // Add welcome message
                _ = try await supabaseService.sendAIResponse(
                    conversationId: newConversation.id,
                    content: welcomeMessage
                )
                
                await loadMessages(for: newConversation.id)
            }
            
            print("✅ Chat initialization complete!")
            isInitializing = false
            
        } catch {
            print("🚨 Failed to initialize chat: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            if let supabaseError = error as? any Error {
                print("🔍 Raw error: \(supabaseError)")
            }
            isInitializing = false
            supabaseService.error = .databaseError("Failed to initialize chat: \(error.localizedDescription)")
        }
    }
    
    private func loadMessages(for conversationId: UUID) async {
        do {
            let chatMessages = try await supabaseService.fetchMessages(for: conversationId)
            messages = chatMessages.map { Message(from: $0) }
        } catch {
            print("Failed to load messages: \(error)")
            supabaseService.error = .databaseError("Failed to load messages")
        }
    }
    
    private func sendMessage() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty, let conversation = currentConversation else { return }
        
        // Clear input immediately for better UX
        let messageContent = trimmedInput
        inputText = ""
        isSending = true
        
        Task {
            // Step 1: Send user message (this should always work)
            do {
                let userMessage = try await supabaseService.sendMessage(
                    conversationId: conversation.id,
                    content: messageContent
                )
                
                // Add to local messages
                let localUserMessage = Message(from: userMessage)
                messages.append(localUserMessage)
                
                print("✅ User message sent successfully")
                
            } catch {
                print("❌ Failed to send user message: \(error)")
                supabaseService.error = .databaseError("Failed to send message")
                isSending = false
                inputText = messageContent // Restore input
                return
            }
            
            // Step 2: Generate AI response (can fail independently)
            do {
                let aiResponseContent = try await aiService.generateResponse(
                    for: messageContent,
                    conversationHistory: messages
                )
                
                let aiMessage = try await supabaseService.sendAIResponse(
                    conversationId: conversation.id,
                    content: aiResponseContent
                )
                
                // Add AI response to local messages
                let localAIMessage = Message(from: aiMessage)
                messages.append(localAIMessage)
                
                print("✅ AI response generated successfully")
                
            } catch {
                print("❌ Failed to generate AI response: \(error)")
                
                // Auto-switch to Mock AI if model fails
                if error.localizedDescription.contains("Model not found") {
                    print("🔄 Auto-switching to Mock AI due to model unavailability")
                    aiService.switchModel(to: .mockAI)
                    
                    // Generate mock response instead
                    let mockProvider = MockAIProvider()
                    let mockResponse = try await mockProvider.generateResponse(for: messageContent, conversationHistory: messages)
                    
                    do {
                        let aiMessage = try await supabaseService.sendAIResponse(
                            conversationId: conversation.id,
                            content: mockResponse
                        )
                        
                        let localAIMessage = Message(from: aiMessage)
                        messages.append(localAIMessage)
                        print("✅ Fallback response sent successfully")
                    } catch {
                        print("❌ Even fallback failed: \(error)")
                    }
                } else {
                    // Show error for other types of failures
                    if let aiError = error as? AIError {
                        aiService.error = aiError
                    } else {
                        aiService.error = .generationFailed(error.localizedDescription)
                    }
                }
            }
            
            isSending = false
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isSending || aiService.isGenerating {
                proxy.scrollTo("loading", anchor: anchor)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: anchor)
            }
        }
    }
    
    // MARK: - API Testing
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
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                        )
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 60)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
