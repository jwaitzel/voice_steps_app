//
//  ReviewVoiceStepView.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/17/24.
//

import SwiftUI
import AVFoundation

class ReviewAudioController: NSObject, AVAudioPlayerDelegate {
    
    var onPlayerFinishPlaying: (() -> ())?
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlayerFinishPlaying?()
    }
}

struct ReviewVoiceStepView: View {
    
    @ObservedObject var flowState: RecordFlowState = .shared
    @ObservedObject var serverStore: ServerStore = .shared
    
    @State private var animateListening: Bool = false
    
    let widthClosed: CGFloat = 140.0
    let widthOpen: CGFloat = UIScreen.main.bounds.width - 16.0

    @State private var secondsPassed: CGFloat = 0.0
    @State private var totalRecordTime: CGFloat = 0.0
    
    @State var midBarFrameIdx: Int = 41 // start at middle
    @State var barFrequencyValues = Array(repeating: 0.01, count: 84)
    
    @State private var player: AVAudioPlayer?
    @State private var isPlaying: Bool = false

    @State var meterDisplayTimer: Timer?
    
    var audioController = ReviewAudioController()

    var body: some View {
        ZStack {
            
            VStack(spacing: 24) {
                
                ZStack {
                    listeningButtonWithsBars
                    
                    Text("REVIEW")
                        .font(.system(size: 24, weight: .semibold))
                        .opacity(animateListening ? 0.0 : 1.0)
                }
                
                Button {
                    playStopAudioAction()
                } label: {
                    Image(systemName: isPlaying ? "stop.circle" : "play.circle")
                        .font(.system(size: 40, weight: .light))
                }
                .foregroundStyle(.primary)
            }
            
            HStack {
                Button {
                    flowState.navPath = .init()
                } label: {
                    ButtonLabel(title: "Redo", imageIcon: "gobackward")
                }
                
                Spacer()
                
                Button {
                    saveVoiceAction()
                } label: {
                    ButtonLabel(title: "Save", imageIcon: "chevron.down")
                }
            }
            .foregroundStyle(.primary)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
//            setupPlayer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                setupPlayer(serverStore.audioGeneratedPlayer)
            }
        }
//        .onChange(of: serverStore.audioGeneratedPlayer) { oldValue, newValue in
//            if newValue != nil {
//                setupPlayer(newValue)
//            }
//        }
        
    }
    
    func saveVoiceAction() {
        print("Finish")
        self.flowState.showChatView = true
        self.flowState.navPath = NavigationPath() // Reset the navpath
    }
    
    func setupPlayer(_ playerP: AVAudioPlayer?) {
        
        if playerP == nil {
            print("Missing player")
            return
        }
//        guard let audioURL = Bundle.main.url(forResource: "audio_javi2", withExtension: "wav") else {
//            print("Missing audio")
//            return
//        }
        
//        player = try? AVAudioPlayer(contentsOf: audioURL)
        player = playerP
        player?.isMeteringEnabled = true
        self.totalRecordTime = CGFloat(player?.duration ?? 0)
        player?.delegate = audioController
        audioController.onPlayerFinishPlaying = {
            stopAudio()
        }
        print("Setup player \(playerP)")
    }
    
    func stopAudio() {
        player?.stop()
        isPlaying = false
        uninstallDisplayLink()
        animateStopBars()
        player?.currentTime = 0
        secondsPassed = 0

    }
    
    func playStopAudioAction() {
        
        if isPlaying {
            stopAudio()
            return
        }
        
        //                serverStore.audioGeneratedPlayer?.play()
        player?.play()
        isPlaying = true
        installDisplayLink()

        withAnimation(.easeInOut(duration: 0.3)) {
            animateListening = true
        }
    }
    
    func animateStopBars() {
        withAnimation(.easeInOut(duration: 1.0)) {
            for i in 0...midBarFrameIdx {
                self.barFrequencyValues[i] = 0.01
            }
        }
    }
    
    fileprivate func installDisplayLink() {
        meterDisplayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true, block: { _ in
            updateMeter()
        })
//        meterDisplayLink?.preferredFramesPerSecond = 20
//        meterDisplayLink?.add(to: .current, forMode: .common)
    }
    
    func updateMeter() {
        
        player?.updateMeters()
        let avgVal = player?.averagePower(forChannel: 0) ?? 0
        let loudValue = scaledValue(Double(avgVal))
        
        secondsPassed = player?.currentTime ?? 0
        
        let midIndex = midBarFrameIdx+1
        barFrequencyValues.insert(loudValue, at: midIndex)
        barFrequencyValues.remove(at: 0)
        
    }
    
    fileprivate func uninstallDisplayLink() {
        if let displayTimer = meterDisplayTimer {
            displayTimer.invalidate()
            meterDisplayTimer = nil
        }
    }

    
    var listeningButtonWithsBars: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .foregroundStyle(.ultraThinMaterial)
            .frame(height: 64.0)
            .overlay {
                meterBarsView
            }
            .frame(width: animateListening ? widthOpen : widthClosed)
            .overlay(alignment: .bottom) {
                let secondsFormat = String(format: "0:%.02d/0:%.02d", Int(secondsPassed), Int(totalRecordTime))
                Text(secondsFormat)
                    .font(.system(size: 12))
                    .padding(.top, 4)
                    .alignmentGuide(.bottom) { d in
                        d[.top]
                    }
                    .opacity(animateListening ? 1 : 0)

            }

    }
    
    var meterBarsView: some View {
        GeometryReader {
            let size = $0.size
            let barFrequencyValues = barFrequencyValues
            let widthForBar = size.width / CGFloat(barFrequencyValues.count)

            HStack(spacing: 1) {
                ForEach(0..<barFrequencyValues.count, id: \.self) { idx in
                    let valFreq = barFrequencyValues[idx]
                    let sizeH = size.height * valFreq /// Half height for each bar
                    let invertedAlpha = (CGFloat(idx) / CGFloat(midBarFrameIdx))
                    Rectangle()
                        .foregroundStyle(.primary)
                        .frame(height: sizeH)
                        .opacity(idx > midBarFrameIdx ? 0 : invertedAlpha)
                        .frame(width: widthForBar-1)
                }
            }
            .frame(height: size.height)
            .opacity(animateListening ? 1 : 0)
        }
        
    }
}

#Preview {
    RecordFlowView()
}
