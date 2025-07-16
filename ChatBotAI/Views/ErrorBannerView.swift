//
//  ErrorBannerView.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import SwiftUI

struct ErrorBannerView: View {
    let error: SupabaseError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
} 