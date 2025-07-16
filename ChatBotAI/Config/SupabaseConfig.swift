//
//  SupabaseConfig.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

struct SupabaseConfig {
    
    // MARK: - Configuration
    // 🚨 IMPORTANT: Replace these with your actual Supabase project credentials
    // You can find these in your Supabase project dashboard under Settings > API
    
    static let projectURL = "https://djjgyyxkzukbjwommqlw.supabase.co" // e.g., "https://your-project-id.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqamd5eXhrenVrYmp3b21tcWx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1OTExOTIsImV4cCI6MjA2ODE2NzE5Mn0.5ZX9Ar_-6YsxPiOU0vgo0Vjd2Lv0Wzjs0eyNHiePJnM" // Your anon/public key (starts with "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
    
    // MARK: - Validation
    
    static var isConfigured: Bool {
        return !projectURL.contains("YOUR_SUPABASE") && 
               !anonKey.contains("YOUR_SUPABASE") &&
               projectURL.hasPrefix("https://") &&
               anonKey.hasPrefix("eyJ")
    }
    
    static func validate() throws {
        guard isConfigured else {
            throw ConfigurationError.missingCredentials
        }
        
        guard let url = URL(string: projectURL) else {
            throw ConfigurationError.invalidURL
        }
        
        guard url.scheme == "https" else {
            throw ConfigurationError.insecureURL
        }
    }
}

// MARK: - Configuration Errors

enum ConfigurationError: LocalizedError {
    case missingCredentials
    case invalidURL
    case insecureURL
    
    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Supabase credentials not configured. Please update SupabaseConfig.swift with your project URL and anon key."
        case .invalidURL:
            return "Invalid Supabase project URL. Please check your configuration."
        case .insecureURL:
            return "Supabase URL must use HTTPS for security."
        }
    }
} 