//
//  RecordOptionsView.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/18/24.
//

import SwiftUI

struct RecordOptionsView: View {
    
    @ObservedObject var flowState: RecordFlowState = .shared

    var body: some View {
        VStack(spacing: 16) {
            TextField("Voice Name", text: $flowState.voiceName)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
            
            Button {
                flowState.voiceLanguage = flowState.voiceLanguage == .eng ? .spa : .eng
            } label: {
                Text("LANG: \(flowState.voiceLanguage.rawValue.uppercased())")
            }
            .foregroundStyle(.primary)
        }
    }
}

#Preview {
    RecordOptionsView()
}
