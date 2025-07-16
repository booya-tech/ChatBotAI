//
//  ChatModels.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

// MARK: - Database Models

/// Represents a chat conversation/session
struct ChatConversation: Identifiable, Codable {
    let id: UUID
    let userId: String
    let title: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Represents a single chat message
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let conversationId: UUID
    let content: String
    let isFromUser: Bool
    let messageType: MessageType
    let status: MessageStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case content
        case isFromUser = "is_from_user"
        case messageType = "message_type"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Message types for future extensibility
enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case file = "file"
    case system = "system"
}

/// Message delivery status
enum MessageStatus: String, Codable, CaseIterable {
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case failed = "failed"
}

// MARK: - Local UI Models

/// Local message model for UI (extends the database model)
struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let status: MessageStatus
    let messageType: MessageType
    
    init(content: String, isFromUser: Bool, status: MessageStatus = .sent, messageType: MessageType = .text) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.status = status
        self.messageType = messageType
    }
    
    /// Initialize from database model
    init(from chatMessage: ChatMessage) {
        self.content = chatMessage.content
        self.isFromUser = chatMessage.isFromUser
        self.timestamp = chatMessage.createdAt
        self.status = chatMessage.status
        self.messageType = chatMessage.messageType
    }
}

// MARK: - API Request/Response Models

struct SendMessageRequest: Codable {
    let conversationId: UUID
    let content: String
    let messageType: MessageType
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case content
        case messageType = "message_type"
    }
}

struct CreateConversationRequest: Codable {
    let userId: String
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
    }
}

struct InsertMessageRequest: Codable {
    let conversationId: String
    let content: String
    let isFromUser: Bool
    let messageType: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case content
        case isFromUser = "is_from_user"
        case messageType = "message_type"
        case status
    }
} 