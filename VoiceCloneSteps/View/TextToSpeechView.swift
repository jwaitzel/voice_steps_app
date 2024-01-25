//
//  TextToSpeechView.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/20/24.
//

import SwiftUI
import AVFoundation

enum MessageToSpeechState {
    case none
    case audioGenerated
}

struct MessageToSpeech {
    var msg: String = ""
    var audioState: MessageToSpeechState = .none
}

let realEstatePhrases: [String] = [
    "Hello, I'd like to rent a ... furnished apartment ... ",
    "From 15th of February",
    "One Month",
    "Thank you. I'm looking forward to it.",
    "Could you show me the property?",
    "What is the monthly rent?",
    "[laughs]",
    "ok, no problem, bye, have a good day",
    "Can I see the lease agreement?",
    "Are pets allowed?",
    "How soon can I move in?",
    "Is there parking available?"
]

struct TextToSpeechView: View {
    
    @State private var messageText: String = "Thank you. I'm looking forward to it."
    @State private var player: AVPlayer?

    @State private var messages: [MessageToSpeech] = realEstatePhrases.map { str -> MessageToSpeech in
        MessageToSpeech(msg: str)
    }
    
    var body: some View {
        
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                chatView
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                
                searchTextField
                
                ChatBarButton("paperplane") {
                    sendMessageAction()
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }

    }
    
    
    @ViewBuilder
    func ChatBarButton(_ icon: String, _ action: @escaping () -> () ) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: icon)
        }
        .foregroundStyle(.primary)
        .padding(.bottom, 12)
        .padding(.horizontal, 8)

    }

    func sendMessageAction() {
        if messageText.isEmpty { return }
        let newMsg = MessageToSpeech(msg: messageText)
        messages.insert(newMsg, at: 0)
        messageText = ""
    }

    var searchTextField: some View {

        TextField(text: $messageText, axis: .vertical) {
            Text("Text to Speech")
        }
        .font(.system(size: 13, weight: .regular))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 12)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .foregroundStyle(.gray.opacity(0.1))
        }
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.black.opacity(0.6), style: .init(lineWidth: 2))
        }

    }

    
    var chatView: some View {
        VStack(spacing: 16) {
            ForEach(0..<messages.count, id: \.self) { idx in
                let msg = messages[idx]
                ChatMessageView(msg, idx)
            }
        }
        .padding(.top, 32)
    }
    
    @ViewBuilder
    func ChatMessageView(_ msg: MessageToSpeech, _ idx: Int) -> some View {
        
        VStack(spacing: 0) {

            HStack {
                Text(msg.msg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 14, weight: .regular))
                    .padding(.leading, 16)
                    .padding(.vertical, 16)
                    .foregroundStyle(.primary)
                
                
                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 16, weight: .light))
                    }
                    .foregroundStyle(.primary)

                    if msg.audioState == .audioGenerated || true {
                        Button {
                            playAudioAction(idx)
                        } label: {
                            Image(systemName: "play.circle")
                                .font(.system(size: 16, weight: .light))
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.trailing, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .foregroundStyle(.secondary.opacity(0.08))
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    func playAudioAction(_ idx: Int) {
        print("Play audio")
    }
    
    func speechToTextMessageAction(_ idx: Int) {
        print("Soeech text")
    }

}

#Preview {
    TextToSpeechView()
}
