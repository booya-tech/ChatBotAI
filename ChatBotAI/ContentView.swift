//
//  ContentView.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import SwiftUI

// MARK: - Service Type Alias
// Change this to SupabaseService once package is linked properly
typealias ChatService = MockSupabaseService

// MARK: - Chat View
struct ContentView: View {
    @StateObject private var supabaseService = ChatService.shared
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var currentConversation: ChatConversation?
    @State private var isInitializing = true
    @State private var isSending = false
    
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
            .task {
                await initializeChat()
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
                        
                        TypingIndicatorView(isTyping: isSending)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isSending) { _ in
                    if isSending {
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
            
            // Input Field
            ChatInputView(
                inputText: $inputText,
                isSending: isSending,
                onSend: sendMessage
            )
        }
    }
    
    // MARK: - Actions
    
    private func initializeChat() async {
        do {
            // Sign in anonymously if not already signed in
            if !supabaseService.isSignedIn {
                try await supabaseService.signInAnonymously()
            }
            
            // Try to get existing conversations or create a new one
            let conversations = try await supabaseService.fetchUserConversations()
            
            if let existingConversation = conversations.first {
                currentConversation = existingConversation
                await loadMessages(for: existingConversation.id)
            } else {
                // Create a new conversation
                let newConversation = try await supabaseService.createConversation(title: "New Chat")
                currentConversation = newConversation
                
                // Add welcome message
                _ = try await supabaseService.sendAIResponse(
                    conversationId: newConversation.id,
                    content: "Hello! I'm your AI assistant. How can I help you today?"
                )
                
                await loadMessages(for: newConversation.id)
            }
            
            isInitializing = false
            
        } catch {
            print("Failed to initialize chat: \(error)")
            isInitializing = false
            supabaseService.error = .databaseError("Failed to initialize chat")
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
            do {
                // Send user message
                let userMessage = try await supabaseService.sendMessage(
                    conversationId: conversation.id,
                    content: messageContent
                )
                
                // Add to local messages
                let localUserMessage = Message(from: userMessage)
                messages.append(localUserMessage)
                
                // Generate and send AI response
                let aiResponseContent = supabaseService.generateAIResponse(to: messageContent)
                
                // Simulate typing delay
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                let aiMessage = try await supabaseService.sendAIResponse(
                    conversationId: conversation.id,
                    content: aiResponseContent
                )
                
                // Add AI response to local messages
                let localAIMessage = Message(from: aiMessage)
                messages.append(localAIMessage)
                
                isSending = false
                
            } catch {
                print("Failed to send message: \(error)")
                supabaseService.error = .databaseError("Failed to send message")
                isSending = false
                
                // Restore input text if sending failed
                inputText = messageContent
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, anchor: UnitPoint = .bottom) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isSending {
                proxy.scrollTo("loading", anchor: anchor)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: anchor)
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
