//
//  NotificationNames.swift
//  ChatBotAI
//
//  Custom notification names for app-wide communication
//

import Foundation

extension Notification.Name {
    static let conversationTitleUpdated = Notification.Name("conversationTitleUpdated")
    static let conversationCreated = Notification.Name("conversationCreated")
    static let conversationDeleted = Notification.Name("conversationDeleted")
} 