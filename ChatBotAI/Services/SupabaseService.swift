//
//  SupabaseService.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    @Published var isLoading = false
    @Published var error: SupabaseError?
    
    private init() {
        do {
            try SupabaseConfig.validate()
            let url = URL(string: SupabaseConfig.projectURL)!
            self.client = SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
        } catch {
            // For development, we'll use placeholder values and show error in UI
            let placeholderURL = URL(string: "https://placeholder.supabase.co")!
            self.client = SupabaseClient(supabaseURL: placeholderURL, supabaseKey: "placeholder-key")
            self.error = .databaseError("Configuration required: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Configuration
    
    func configure(url: String, anonKey: String) {
        // This method can be called to update credentials if needed
        // For now, credentials are set in init
    }
    
    // MARK: - Authentication
    
    var currentUser: User? {
        client.auth.currentUser
    }
    
    var isSignedIn: Bool {
        currentUser != nil
    }
    
    func signInAnonymously() async throws {
        print("🔐 Attempting anonymous sign in...")
        try await client.auth.signInAnonymously()
        
        if let user = currentUser {
            print("✅ Anonymous sign in successful! User ID: \(user.id.uuidString)")
        } else {
            print("❌ Anonymous sign in failed - no user returned")
            throw SupabaseError.notAuthenticated
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Conversations
    
    func createConversation(title: String) async throws -> ChatConversation {
        // Ensure user is authenticated
        guard let user = currentUser else {
            throw SupabaseError.notAuthenticated
        }
        
        let userId = user.id.uuidString
        print("🔍 Creating conversation for user: \(userId)")
        
        isLoading = true
        error = nil
        
        do {
            let request = CreateConversationRequest(userId: userId, title: title)
            
            let response: ChatConversation = try await client
                .from("conversations")
                .insert(request)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Successfully created conversation: \(response.id)")
            isLoading = false
            return response
        } catch {
            print("❌ Failed to create conversation: \(error)")
            isLoading = false
            self.error = SupabaseError.databaseError(error.localizedDescription)
            throw error
        }
    }
    
    func fetchUserConversations() async throws -> [ChatConversation] {
        guard let userId = currentUser?.id.uuidString else {
            throw SupabaseError.notAuthenticated
        }
        
        isLoading = true
        error = nil
        
        do {
            let response: [ChatConversation] = try await client
                .from("conversations")
                .select()
                .eq("user_id", value: userId)
                .order("updated_at", ascending: false)
                .execute()
                .value
            
            isLoading = false
            return response
        } catch {
            isLoading = false
            self.error = SupabaseError.databaseError(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Messages
    
    func fetchMessages(for conversationId: UUID) async throws -> [ChatMessage] {
        isLoading = true
        error = nil
        
        do {
            let response: [ChatMessage] = try await client
                .from("messages")
                .select()
                .eq("conversation_id", value: conversationId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            isLoading = false
            return response
        } catch {
            isLoading = false
            self.error = SupabaseError.databaseError(error.localizedDescription)
            throw error
        }
    }
    
    func sendMessage(
        conversationId: UUID,
        content: String,
        messageType: MessageType = .text
    ) async throws -> ChatMessage {
        isLoading = true
        error = nil
        
        do {
            let request = SendMessageRequest(
                conversationId: conversationId,
                content: content,
                messageType: messageType
            )
            
            let messageRequest = InsertMessageRequest(
                conversationId: conversationId.uuidString,
                content: content,
                isFromUser: true,
                messageType: messageType.rawValue,
                status: MessageStatus.sent.rawValue
            )
            
            let response: ChatMessage = try await client
                .from("messages")
                .insert(messageRequest)
                .select()
                .single()
                .execute()
                .value
            
            isLoading = false
            return response
        } catch {
            isLoading = false
            self.error = SupabaseError.databaseError(error.localizedDescription)
            throw error
        }
    }
    
    func sendAIResponse(
        conversationId: UUID,
        content: String,
        messageType: MessageType = .text
    ) async throws -> ChatMessage {
        do {
            let messageRequest = InsertMessageRequest(
                conversationId: conversationId.uuidString,
                content: content,
                isFromUser: false,
                messageType: messageType.rawValue,
                status: MessageStatus.sent.rawValue
            )
            
            let response: ChatMessage = try await client
                .from("messages")
                .insert(messageRequest)
                .select()
                .single()
                .execute()
                .value
            
            return response
        } catch {
            self.error = SupabaseError.databaseError(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Realtime Subscriptions
    
    func subscribeToMessages(
        conversationId: UUID,
        onMessage: @escaping (ChatMessage) -> Void
    ) async {
        // TODO: Implement realtime subscription once core functionality is working
        // For now, we'll rely on manual refresh/polling
        print("Realtime subscription not yet implemented")
    }
    
    // MARK: - Debug Methods
    
    func testDatabaseConnection() async throws {
        guard let user = currentUser else {
            throw SupabaseError.notAuthenticated
        }
        
        print("🧪 Testing database connection...")
        print("🧪 User ID: \(user.id.uuidString)")
        
        // Test if we can query conversations table
        do {
            let _: [ChatConversation] = try await client
                .from("conversations")
                .select()
                .execute()
                .value
            print("✅ Can query conversations table")
        } catch {
            print("❌ Cannot query conversations table: \(error)")
        }
        
        // Test if we can insert a simple conversation
        do {
            let testRequest = CreateConversationRequest(
                userId: user.id.uuidString,
                title: "Test Conversation"
            )
            
            let _: ChatConversation = try await client
                .from("conversations")
                .insert(testRequest)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Can insert conversation")
        } catch {
            print("❌ Cannot insert conversation: \(error)")
        }
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

// MARK: - Error Types

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case databaseError(String)
    case realtimeError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .realtimeError(let message):
            return "Realtime error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
} 
