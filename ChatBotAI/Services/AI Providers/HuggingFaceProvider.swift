//
//  HuggingFaceProvider.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

class HuggingFaceProvider: AIProvider {
    let name = "Hugging Face"
    let model = "meta-llama/Llama-2-7b-chat-hf"
    
    private let apiKey: String?
    private let baseURL = "https://api-inference.huggingface.co/models"
    
    init() {
        self.apiKey = AIConfig.huggingFaceAPIKey
    }
    
    var isAvailable: Bool {
        return AIConfig.hasHuggingFaceKey
    }
    
    func generateResponse(
        for message: String,
        conversationHistory: [Message]
    ) async throws -> String {
        guard let apiKey = apiKey else {
            throw AIError.providerNotConfigured("Hugging Face API key not found")
        }
        
        let url = URL(string: "\(baseURL)/\(model)")!
        
        // Build conversation context for Llama format
        var conversation = ""
        
        // Add conversation history (last 5 messages for context)
        for historyMessage in conversationHistory.suffix(5) {
            if historyMessage.isFromUser {
                conversation += "[INST] \(historyMessage.content) [/INST] "
            } else {
                conversation += "\(historyMessage.content) "
            }
        }
        
        // Add current message
        conversation += "[INST] \(message) [/INST]"
        
        let requestBody: [String: Any] = [
            "inputs": conversation,
            "parameters": [
                "max_new_tokens": 512,
                "temperature": 0.7,
                "top_p": 0.95,
                "repetition_penalty": 1.1,
                "return_full_text": false
            ],
            "options": [
                "wait_for_model": true,
                "use_cache": false
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🤖 Sending request to Hugging Face: \(model)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        print("📡 Hugging Face response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 429 {
            throw AIError.rateLimitExceeded
        }
        
        if httpResponse.statusCode == 503 {
            throw AIError.generationFailed("Model is loading, please try again in a few moments")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorData = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.generationFailed("HTTP \(httpResponse.statusCode): \(errorData)")
        }
        
        // Parse response
        if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let firstResult = json.first,
           let generatedText = firstResult["generated_text"] as? String {
            
            let cleanedResponse = generatedText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "[INST]", with: "")
                .replacingOccurrences(of: "[/INST]", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return cleanedResponse.isEmpty ? "I'm here to help!" : cleanedResponse
            
        } else if let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let error = errorJson["error"] as? String {
            throw AIError.generationFailed(error)
        } else {
            throw AIError.invalidResponse
        }
    }
} 