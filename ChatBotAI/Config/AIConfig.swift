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
    
    /// Hugging Face API Token (Free)
    /// Get from: https://huggingface.co/settings/tokens
    static let huggingFaceAPIKey = APIKeys.huggingFaceAPIKey
    
    /// Google Gemini API Key (Free - 15 RPM)
    /// Get from: https://makersuite.google.com/app/apikey
    static let googleGeminiAPIKey = APIKeys.googleGeminiAPIKey
    
    /// Groq API Key (Free - 30 RPM)
    /// Get from: https://console.groq.com/keys
    static let groqAPIKey = APIKeys.groqAPIKey
    
    // MARK: - Validation
    
    static var hasHuggingFaceKey: Bool {
        let isValid = !huggingFaceAPIKey.contains("YOUR_") && 
                     !huggingFaceAPIKey.contains("PASTE_") &&
                     !huggingFaceAPIKey.isEmpty && 
                     huggingFaceAPIKey.hasPrefix("hf_") &&
                     huggingFaceAPIKey.count >= 30 // HF tokens are typically 30+ chars
        print("🔑 Hugging Face API key valid: \(isValid)")
        print("🔑 Key format: \(String(huggingFaceAPIKey.prefix(10)))...")
        print("🔑 Key length: \(huggingFaceAPIKey.count)")
        return isValid
    }
    
    // MARK: - Token Verification
    static func testHuggingFaceToken() async -> (isValid: Bool, error: String?) {
        guard hasHuggingFaceKey else {
            return (false, "No valid API key configured")
        }
        
        do {
            let url = URL(string: "https://api-inference.huggingface.co/models/microsoft/DialoGPT-small")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(huggingFaceAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let testPayload = ["inputs": "Hello"]
            request.httpBody = try JSONSerialization.data(withJSONObject: testPayload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200, 503: // 503 = model loading (but token is valid)
                    return (true, nil)
                case 401:
                    return (false, "Invalid or expired token")
                case 404:
                    return (false, "Model not accessible with this token")
                default:
                    return (false, "HTTP \(httpResponse.statusCode)")
                }
            }
            
            return (false, "Invalid response")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    static var hasGoogleGeminiKey: Bool {
        !googleGeminiAPIKey.contains("YOUR_") && !googleGeminiAPIKey.isEmpty
    }
    
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
        hasHuggingFaceKey || hasGoogleGeminiKey || hasGroqKey
    }
} 