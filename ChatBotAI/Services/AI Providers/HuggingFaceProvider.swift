//
//  HuggingFaceProvider.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

class HuggingFaceProvider: AIProvider {
    let name = "Hugging Face"
    let model = "microsoft/DialoGPT-small"
    
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
        
        // Build conversation context for DialoGPT
        var conversation = message
        
        // Add conversation history (last 3 messages for context)
        for historyMessage in conversationHistory.suffix(3) {
            conversation = "\(historyMessage.content) " + conversation
        }
        
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
        print("🔑 Using API key: \(String(apiKey.prefix(10)))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        print("📡 Hugging Face response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw AIError.generationFailed("Invalid API key. Please check your Hugging Face token.")
        }
        
        if httpResponse.statusCode == 404 {
            let errorData = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🚨 404 Error details: \(errorData)")
            throw AIError.generationFailed("Model not found. Switching to Mock AI...")
        }
        
        if httpResponse.statusCode == 429 {
            throw AIError.rateLimitExceeded
        }
        
        if httpResponse.statusCode == 503 {
            throw AIError.generationFailed("Model is loading, please try again in a few moments")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorData = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🚨 Error response: \(errorData)")
            throw AIError.generationFailed("HTTP \(httpResponse.statusCode): API Error")
        }
        
        // Parse response
        if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let firstResult = json.first,
           let generatedText = firstResult["generated_text"] as? String {
            
            let cleanedResponse = generatedText
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