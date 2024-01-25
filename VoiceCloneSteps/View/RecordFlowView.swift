//
//  RecordFlowView.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/17/24.
//

import SwiftUI



struct RecordFlowView: View {
    
    @ObservedObject var flowState: RecordFlowState = .shared
    
    var body: some View {
        NavigationStack(path: $flowState.navPath) {
            RecordFlowHomeView()
        }
    }
}

#Preview {
    RecordFlowView()
}
