//
//  RecordStepView.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/17/24.
//

import SwiftUI
import AVFoundation


struct RecordStepView: View {
    
    @ObservedObject var flowState: RecordFlowState = .shared
    @ObservedObject var audioController: AudioController = .shared
    @ObservedObject var serverStore: ServerStore = .shared
    
    @State private var showOptions: Bool = false
    
    let widthClosed: CGFloat = 140.0
    let widthOpen: CGFloat = UIScreen.main.bounds.width - 16.0
    
    let engText = "Record a 5 to 10 seconds audio with a clear voice and no background noise for good results"
    let spaText = "Graba un audio de 5 a 10 segundos con una voz clara y sin ruido de fondo para obtener buenos resultados"
    @State private var textForRecordHelp: String = ""
    
    @State private var animateNoServer: Bool = false
    
    var body: some View {
        ZStack {
            
            let hasRecording = audioController.player != nil

            VStack(spacing: 24) {
                
                ZStack {
                    listeningButtonWithsBars
                    
                    Text("RECORD")
                        .font(.system(size: 24, weight: .semibold))
                        .opacity(audioController.animateListening ? 0.0 : 1.0)
                }
                
                HStack(spacing: 12) {
                    let isRecording = audioController.isRecording
                    
                    if !hasRecording {
                        Button {
                            audioController.startStopRecodingAction()
                        } label: {
                            Image(systemName: isRecording ? "stop.circle" : "mic.circle")
                                .font(.system(size: 40, weight: .light))
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    if hasRecording {
                        let isPlaying = audioController.isPlaying
                        Button {
                            audioController.startStopAudioPlayer()
                        } label: {
                            Image(systemName: isPlaying ? "stop.circle" : "play.circle")
                                .font(.system(size: 40, weight: .light))
                        }
                        .foregroundStyle(.primary)
                        
                        Button {
                            audioController.deleteRecording()
                        } label: {
                            Image(systemName: "trash.circle")
                                .font(.system(size: 40, weight: .light))
                        }
                        .foregroundStyle(.primary)
                    }
                }

            }
            
            Text("No server")
                .frame(maxHeight: .infinity, alignment: .bottom)
                .offset(y: animateNoServer ? 0 : 120)
           
            
            Text(textForRecordHelp)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .offset(y: 120)
                .padding(.horizontal, 32)
            
            
            let disableNext = !hasRecording && !animateNoServer
            Button {
                self.nextAction()
            } label: {
                
                ButtonLabel(title: "Next", imageIcon: "chevron.right")
            }
            .disabled(disableNext)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 24)
            .opacity(disableNext ? 0.6 : 1.0)
            
            Button {
                showOptions.toggle()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading, 24)
            .padding(.bottom, 12)

        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                serverStore.connectToSocket()
            }
            textForRecordHelp = engText
        }
        .sheet(isPresented: $showOptions, content: {
            RecordOptionsView()
                .presentationDetents([.height(200)])
        })
        .onChange(of: flowState.voiceLanguage) { oldValue, newValue in
            if newValue == .eng {
                textForRecordHelp = engText
            } else {
                textForRecordHelp = spaText
            }
        }
        .onChange(of: serverStore.serverState) { oldValue, newValue in
            if newValue == .noServer {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.animateNoServer = true
                }
            }
        }
    }
    

    var listeningButtonWithsBars: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .foregroundStyle(.ultraThinMaterial)
            .frame(height: 64.0)
            .overlay {
                meterBarsView
            }
            .frame(width: audioController.animateListening ? widthOpen : widthClosed)
            .overlay(alignment: .bottom) {
                let secondsFormat = audioController.isPlaying ? String(format: "0:%.02d/0:%.02d", Int(audioController.secondsPassed), Int(audioController.totalRecordTime)) : String(format: "0:%.02d", Int(audioController.secondsPassed))
                Text(secondsFormat)
                    .font(.system(size: 12))
                    .padding(.top, 4)
                    .alignmentGuide(.bottom) { d in
                        d[.top]
                    }
                    .opacity(audioController.animateListening ? 1 : 0)

            }

    }
    
    var meterBarsView: some View {
        GeometryReader {
            let size = $0.size
            let barFrequencyValues = audioController.barFrequencyValues
            let widthForBar = size.width / CGFloat(barFrequencyValues.count)

            HStack(spacing: 1) {
                ForEach(0..<barFrequencyValues.count, id: \.self) { idx in
                    let valFreq = barFrequencyValues[idx]
                    let sizeH = size.height * valFreq /// Half height for each bar
                    let invertedAlpha = (CGFloat(idx) / CGFloat(audioController.midBarFrameIdx))
                    Rectangle()
                        .foregroundStyle(.primary)
                        .frame(height: sizeH)
                        .opacity(idx > audioController.midBarFrameIdx ? 0 : invertedAlpha)
                        .frame(width: widthForBar-1)
                }
            }
            .frame(height: size.height)
            .opacity(audioController.animateListening ? 1 : 0)
        }
        
    }

    
    func nextAction() {
        /// Send audio to server
        if animateNoServer { // Debug for no server
            flowState.navPath.append(Routes.loading)
            return
        }
        guard let recordingFile = audioController.recordingFileURL else { print("No recording file"); return; }
        
        do {
            
            /// Send request
            let fileData = try Data(contentsOf: recordingFile, options: NSData.ReadingOptions.mappedIfSafe)
            let dataString = fileData.base64EncodedString()
            let msgSocket = SocketMessageData(type: "train", voiceName: flowState.voiceName, fileData64: dataString, lang: flowState.voiceLanguage.rawValue)

            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(msgSocket)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                serverStore.task?.send(message) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            print("WebSocket sending error: \(error)")
                        }
                    } else {
                        print("Send frame req success ")
                    }
                }
            }
//            print("Data to send \(dataString)")
        } catch {
            print(error)
            return
        }

        flowState.navPath.append(Routes.loading)

    }
}

struct ButtonLabel: View {
    
    var title: String
    var imageIcon: String
    init(title: String, imageIcon: String) {
        self.title = title
        self.imageIcon = imageIcon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .foregroundStyle(.background)
                .font(.system(size: 18))
            
            Image(systemName: imageIcon)
                .foregroundStyle(.background)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    RecordStepView()
        .preferredColorScheme(Int.random(in:0...100) < 50 ? .dark : .light)
}
