//
//  AIConfig.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

struct AIConfig {
    
    // MARK: - API Keys Configuration
    // 🔐 API keys are now loaded from secure APIKeys.swift (gitignored)
    
    /// Groq API Key (Free - 30 RPM)
    /// Get from: https://console.groq.com/keys
    static let groqAPIKey = APIKeys.groqAPIKey
    
    // MARK: - Groq Token Verification
    static func testGroqToken() async -> (isValid: Bool, error: String?) {
        guard hasGroqKey else {
            return (false, "No valid API key configured")
        }
        
        do {
            let url = URL(string: "https://api.groq.com/openai/v1/models")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(groqAPIKey)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    return (true, nil)
                case 401:
                    return (false, "Invalid or expired token")
                default:
                    return (false, "HTTP \(httpResponse.statusCode)")
                }
            }
            
            return (false, "Invalid response")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    static var hasGroqKey: Bool {
        let isValid = !groqAPIKey.contains("YOUR_") && 
                     !groqAPIKey.isEmpty && 
                     groqAPIKey.hasPrefix("gsk_") &&
                     groqAPIKey.count >= 50 // Groq tokens are typically 50+ chars
        print("🔑 Groq API key valid: \(isValid)")
        print("🔑 Key format: \(String(groqAPIKey.prefix(10)))...")
        print("🔑 Key length: \(groqAPIKey.count)")
        return isValid
    }
    
    static var hasAnyKey: Bool {
        hasGroqKey
    }
} 