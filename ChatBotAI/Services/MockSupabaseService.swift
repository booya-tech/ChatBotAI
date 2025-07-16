//
//  MockSupabaseService.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

// Mock service for testing while Supabase package is being configured
@MainActor
class MockSupabaseService: ObservableObject {
    static let shared = MockSupabaseService()
    
    @Published var isLoading = false
    @Published var error: SupabaseError?
    
    private var mockConversations: [ChatConversation] = []
    private var mockMessages: [ChatMessage] = []
    private let mockUserId = "mock-user-123"
    
    private init() {}
    
    // MARK: - Authentication
    
    var currentUser: MockUser? {
        MockUser(id: UUID(), uuidString: mockUserId)
    }
    
    var isSignedIn: Bool { true }
    
    func signInAnonymously() async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func signOut() async throws {
        // Mock sign out
    }
    
    // MARK: - Conversations
    
    func createConversation(title: String) async throws -> ChatConversation {
        isLoading = true
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let conversation = ChatConversation(
            id: UUID(),
            userId: mockUserId,
            title: title,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockConversations.append(conversation)
        isLoading = false
        return conversation
    }
    
    func fetchUserConversations() async throws -> [ChatConversation] {
        isLoading = true
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        isLoading = false
        return mockConversations
    }
    
    // MARK: - Messages
    
    func fetchMessages(for conversationId: UUID) async throws -> [ChatMessage] {
        isLoading = true
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        let messages = mockMessages.filter { $0.conversationId == conversationId }
        isLoading = false
        return messages
    }
    
    func sendMessage(
        conversationId: UUID,
        content: String,
        messageType: MessageType = .text
    ) async throws -> ChatMessage {
        isLoading = true
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let message = ChatMessage(
            id: UUID(),
            conversationId: conversationId,
            content: content,
            isFromUser: true,
            messageType: messageType,
            status: .sent,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockMessages.append(message)
        isLoading = false
        return message
    }
    
    func sendAIResponse(
        conversationId: UUID,
        content: String,
        messageType: MessageType = .text
    ) async throws -> ChatMessage {
        // Simulate AI processing delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let message = ChatMessage(
            id: UUID(),
            conversationId: conversationId,
            content: content,
            isFromUser: false,
            messageType: messageType,
            status: .sent,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockMessages.append(message)
        return message
    }
    
    // MARK: - Realtime (Mock)
    
    func subscribeToMessages(
        conversationId: UUID,
        onMessage: @escaping (ChatMessage) -> Void
    ) async {
        print("Mock: Realtime subscription simulated")
    }
    
    // MARK: - Helper Methods
    
    func generateAIResponse(to userMessage: String) -> String {
        let responses = [
            "That's an interesting question! Let me think about that.",
            "I understand what you're asking. Here's my perspective on that.",
            "Thanks for sharing that with me. I'd be happy to help!",
            "That's a great point. Let me elaborate on that topic.",
            "I see what you mean. Here's how I would approach that.",
            "Absolutely! That's something I can definitely help you with.",
            "Good question! Let me break that down for you.",
            "I appreciate you asking about that. Here's what I think.",
            "Based on what you're saying, I think the best approach would be...",
            "Let me help you with that. Here's what I recommend..."
        ]
        return responses.randomElement() ?? "I'm here to help!"
    }
}

// MARK: - Mock User

struct MockUser {
    let id: UUID
    let uuidString: String
} 