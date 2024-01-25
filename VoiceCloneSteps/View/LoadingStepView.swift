//
//  LoadingStepView.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/17/24.
//

import SwiftUI

struct LoadingStepView: View {
    
    @ObservedObject var flowState: RecordFlowState = .shared
    @ObservedObject var serverStore: ServerStore = .shared
    
    enum RowState {
        case none
        case loading
        case success
        case error
        case explosion
    }

    @State private var audioState: RowState = .loading
    @State private var modelState: RowState = .none
    @State private var voiceState: RowState = .none
    @State private var generationState: RowState = .none
    
    @State private var loadingStepIdx: Int = 0
    @State private var animateExplosion: Bool = false

    var body: some View {
        ZStack {
            
            Text("LOADING")
                .font(.system(size: 24, weight: .semibold))

            VStack(spacing: 0) {
                LoadingRow("Audio Loaded", state: audioState)
                LoadingRow("Model Loaded", state: modelState)
                LoadingRow("Voice Training", state: voiceState)
                LoadingRow("Audio Generation", state: generationState, speciaRow: true)
            }
            .frame(width: 240)
            .overlay(alignment: .bottom) {
                if serverStore.serverState == .noServer { /// Debug
                    Text("Tap to continue")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .offset(y: 44)
                }
            }
            .offset(y: 140)
            
            Button {
                flowState.navPath.append(Routes.review)
            } label: {
                Text("SKIP")
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(0)
        }
        .onChange(of: serverStore.loadingState) { _, newValue  in
            if newValue == .audioLoaded {
                audioState = .success
                modelState = .loading
            } else if newValue == .modelLoaded {
                modelState = .success
                voiceState = .loading
            } else if newValue == .voiceSaved {
                voiceState = .success
                generationState = .loading
            } else if newValue == .audioGenerated {
                animateExplosion = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    generationState = .success
                }
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.2) {
                    flowState.navPath.append(Routes.review)
                }
            }
        }
        .contentShape(.rect)
        /// - Debug code animation with tap
        .onTapGesture {
            loadingStepIdx += 1
            if loadingStepIdx == 1 {
                audioState = .success
                modelState = .loading
            } else if loadingStepIdx == 2 {
                modelState = .success
                voiceState = .loading
            } else if loadingStepIdx == 3 {
                voiceState = .success
                withAnimation(.easeInOut(duration: 0.23)) {
                    generationState = .loading
                }
                
            } else if loadingStepIdx == 4 {
                animateExplosion = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    generationState = .success
                }
                if serverStore.serverState == .noServer { /// Debeg for no server
                    DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.0) {
                        flowState.navPath.append(Routes.review)
                    }
                }
            } else if loadingStepIdx == 5 {
                audioState = .loading
                modelState = .none
                voiceState = .none
                generationState = .none
                animateExplosion = false
                loadingStepIdx = 0
            }
        }

        
    }
    
    
    @ViewBuilder
    func LoadingRow(_ text: String, state: RowState, speciaRow: Bool = false) -> some View {
        HStack {
            Text(text)
            
            Spacer()
            
            ZStack {
                
                if speciaRow {
                    LoadingParticlesView(animateExplosion: $animateExplosion)
                        .opacity(state == .loading || state == .success ? 1 : 0)
                }
                switch state {
                case .none:
                    Circle()
                        .stroke(.primary.opacity(0.04), lineWidth: 2)
                        .frame(width: 14, height: 14)
                case .loading:
                    ZStack {
                        if speciaRow {
                            EmptyView()
                        } else {
                            ProgressView()
                        }
                    }
                case .success:
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                        .frame(width: 16, height: 16)

                case .error:
                    Image(systemName: "xmark.circle")
                case .explosion:
                    EmptyView()
                }

            }
            .frame(width: 48, height: 48)
            
        }
    }
}

#Preview {
    LoadingStepView()
        .preferredColorScheme(.dark)
}
