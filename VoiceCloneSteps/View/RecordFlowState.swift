//
//  RecordFlowState.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/18/24.
//

import SwiftUI

enum Routes: String {
    case loading
    case review
}

enum RecordLanguage: String {
    case eng
    case spa
}

class RecordFlowState: ObservableObject {
    
    static var shared: RecordFlowState = .init()
    
    @Published var navPath: NavigationPath = .init()
    @Published var showChatView: Bool = false
    
    @Published var voiceName: String = "javi3"
    
    @Published var voiceLanguage: RecordLanguage = .eng
    
}

