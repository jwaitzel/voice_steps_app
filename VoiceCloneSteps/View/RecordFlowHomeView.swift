//
//  RecordFlowHomeView.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/21/24.
//

import SwiftUI

struct RecordFlowHomeView: View {
    
    @ObservedObject var flowState: RecordFlowState = .shared

    var body: some View {
        if flowState.showChatView {
            TextToSpeechView()
        } else {
            RecordStepView()
                .navigationDestination(for: Routes.self) { newRoute in
                    switch newRoute {
                    case .loading:
                        LoadingStepView()
                            .toolbar(.hidden, for: .navigationBar)
                    case .review:
                        ReviewVoiceStepView()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
        }
    }
}
#Preview {
    RecordFlowHomeView()
}
