//
//  AIConfig.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

struct AIConfig {
    
    // MARK: - API Keys Configuration
    // 🚨 IMPORTANT: Replace with your actual API keys
    
    /// Hugging Face API Token (Free)
    /// Get from: https://huggingface.co/settings/tokens
    static let huggingFaceAPIKey = "YOUR_HUGGING_FACE_API_KEY"
    
    /// Google Gemini API Key (Free - 15 RPM)
    /// Get from: https://makersuite.google.com/app/apikey
    static let googleGeminiAPIKey = "YOUR_GOOGLE_GEMINI_API_KEY"
    
    /// Groq API Key (Free - 30 RPM)
    /// Get from: https://console.groq.com/keys
    static let groqAPIKey = "YOUR_GROQ_API_KEY"
    
    // MARK: - Validation
    
    static var hasHuggingFaceKey: Bool {
        !huggingFaceAPIKey.contains("YOUR_") && !huggingFaceAPIKey.isEmpty
    }
    
    static var hasGoogleGeminiKey: Bool {
        !googleGeminiAPIKey.contains("YOUR_") && !googleGeminiAPIKey.isEmpty
    }
    
    static var hasGroqKey: Bool {
        !groqAPIKey.contains("YOUR_") && !groqAPIKey.isEmpty
    }
    
    static var hasAnyKey: Bool {
        hasHuggingFaceKey || hasGoogleGeminiKey || hasGroqKey
    }
} 