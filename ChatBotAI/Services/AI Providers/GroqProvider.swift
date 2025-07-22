//
//  GroqProvider.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

class GroqProvider: AIProvider {
    let name = "Groq"
    let model = "llama-3.1-8b-instant"
    
    var isAvailable: Bool {
        return AIConfig.hasGroqKey
    }
    
    func generateResponse(
        for message: String,
        conversationHistory: [Message]
    ) async throws -> String {
        // TODO: Implement Groq API integration
        throw AIError.providerNotConfigured("Groq provider not yet implemented")
    }
} 