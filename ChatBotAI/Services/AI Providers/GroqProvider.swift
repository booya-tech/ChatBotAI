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
    
    private let apiKey: String?
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    
    init() {
        self.apiKey = AIConfig.hasGroqKey ? AIConfig.groqAPIKey : nil
    }
    
    var isAvailable: Bool {
        return AIConfig.hasGroqKey && apiKey != nil
    }
    
    func generateResponse(
        for message: String,
        conversationHistory: [Message]
    ) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIError.providerNotConfigured("Groq API key not configured")
        }
        
        // Build conversation messages for Groq (OpenAI format)
        var messages: [[String: String]] = []
        
        // Add system message
        messages.append([
            "role": "system",
            "content": "You are a helpful AI assistant. Keep responses concise and friendly."
        ])
        
        // Add conversation history (last 5 messages for context)
        for historyMessage in conversationHistory.suffix(5) {
            let role = historyMessage.isFromUser ? "user" : "assistant"
            messages.append([
                "role": role,
                "content": historyMessage.content
            ])
        }
        
        // Add current user message
        messages.append([
            "role": "user",
            "content": message
        ])
        
        // Prepare request
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": 150,
            "temperature": 0.7,
            "top_p": 1,
            "stream": false
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIError.generationFailed("Failed to encode request body")
        }
        
        print("🚀 Sending request to Groq: \(model)")
        print("🔑 Using API key: \(String(apiKey.prefix(10)))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        print("📡 Groq response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw AIError.generationFailed("Invalid Groq API key. Please check your token.")
        }
        
        if httpResponse.statusCode == 429 {
            throw AIError.rateLimitExceeded
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorData = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🚨 Groq error response: \(errorData)")
            throw AIError.generationFailed("HTTP \(httpResponse.statusCode): API Error")
        }
        
        // Parse response
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AIError.invalidResponse
            }
            
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedContent.isEmpty {
                throw AIError.generationFailed("Received empty response from Groq")
            }
            
            print("✅ Groq response generated successfully")
            return trimmedContent
            
        } catch {
            print("🚨 Failed to parse Groq response: \(error)")
            throw AIError.invalidResponse
        }
    }
} 
