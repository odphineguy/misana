//
//  ChatMessage.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import Foundation

/// Represents a single message in the chat conversation
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}
