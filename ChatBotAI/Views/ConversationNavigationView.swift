//
//  ConversationNavigationView.swift
//  ChatBotAI
//
//  Navigation controller for managing conversations and chat interface
//

import SwiftUI

struct ConversationNavigationView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var navigationPath = NavigationPath()
    @State private var isShowingNewChat = false
    @State private var conversationListRefreshTrigger = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // 📱 Root: Conversation List
            ConversationListView(
                navigationPath: $navigationPath,
                isShowingNewChat: $isShowingNewChat,
                refreshTrigger: $conversationListRefreshTrigger
            )
            .navigationDestination(for: ChatConversation.self) { conversation in
                // 💬 Destination: Chat Interface
                ChatDetailView(conversation: conversation)
            }
        }
        .onAppear {
            initializeApp()
        }
        .sheet(isPresented: $isShowingNewChat) {
            NewChatView(
                isPresented: $isShowingNewChat,
                navigationPath: $navigationPath,
                onConversationCreated: {
                    // Trigger refresh of conversation list
                    conversationListRefreshTrigger.toggle()
                }
            )
        }
    }
    
    // MARK: - Initialization
    
    private func initializeApp() {
        Task {
            try await supabaseService.signInAnonymously()
        }
    }
}

#Preview {
    ConversationNavigationView()
} 

