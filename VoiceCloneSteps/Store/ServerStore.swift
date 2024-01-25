//
//  ServerStore.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/18/24.
//

import SwiftUI
import AVFoundation

let kHOST_URL = "y48i2gxvpfkj6t" // RUNPOD ID
let kHOST_PORT = "8000" // PORT - Should be in the Exposed HTTP Ports section in Runpod Pod settings

enum ServerState: String, CaseIterable {
    case unactive
    case loading
    case connected
    case loaded
    case cancelled
    case error
    case noServer
}

enum LoadingState: String {
    case none
    case audioLoaded
    case modelLoaded
    case voiceSaved
    case audioGenerated
}

struct SocketMessageData: Codable {
    var type: String
    var voiceName: String?
    var fileData64:String?
    var lang: String?
}

struct RequestAudio: Codable {
    let filename: String
    let fileData64: String
}

class ServerStore: NSObject, ObservableObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    static var shared: ServerStore = .init()
    
    var task: URLSessionWebSocketTask?

    @Published var serverState: ServerState = .unactive
    @State var errorMessage: String = ""
    
    @Published var loadingState: LoadingState = .none
    
    @Published var audioGeneratedPlayer: AVAudioPlayer?


    //MARK: - Functions
    func connectToSocket() {
        
        let customQueue = OperationQueue()
        let conf = URLSessionConfiguration.default
        
        let url = urlForSocket()
        let urlSession = URLSession(configuration: conf, delegate: self, delegateQueue: customQueue)
        let urlRequest = URLRequest(url: url)
        task = urlSession.webSocketTask(with: urlRequest)
        task!.maximumMessageSize = 1024 * 1024 * 10 // 10 mb max image
        task!.delegate = self
        self.listenForMesssages()
        task!.resume()
        
        DispatchQueue.main.async {
            self.serverState = .loading
        }
    }

    func urlForSocket() -> URL {
        let url = URL(string: "ws://\(kHOST_URL)-\(kHOST_PORT).proxy.runpod.net/audio_train/")!
        return url
    }
    
    func listenForMesssages() {
        task?.receive(completionHandler: {[weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                //                self.manager.socketDidClose()
            case .success(let message):
                self?.receiveMessage(message)
                if self?.task?.state == .running {
                    self?.listenForMesssages()
                }
            }
        })
    }
    
    func receiveMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let jsonData = text.data(using: .utf8) {
                do {
                    if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        self.handleReceivedMessage(jsonDict)
                    } else {
                        print("Error parsing JSON response")
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            } else {
                print("no utf")
            }
            //            receiveTextMessage(text)
//            print("Received: \(text)")
        case .data(let data):
            print("Received binary message: \(data)")
        @unknown default:
            print("uknown")
        }
    }
    
    func handleReceivedMessage(_ msg: [String: Any]) {
        let receivedMsg = msg["message"] as? String ?? ""
        print("Received message \(receivedMsg)")
        if receivedMsg == "connected" {
            DispatchQueue.main.async {
                self.serverState = .connected
            }
        } else if receivedMsg == "audioFileLoaded" {
            DispatchQueue.main.async {
                self.loadingState = .audioLoaded
            }
        } else if receivedMsg == "modelLoaded" {
            DispatchQueue.main.async {
                self.loadingState = .modelLoaded
            }
        } else if receivedMsg == "voiceSaved" {
            DispatchQueue.main.async {
                self.loadingState = .voiceSaved
            }
        } else if receivedMsg == "audioGenerated" {
            
            if let base64String = msg["fileData"] as? String,
               let convertedData = Data(base64Encoded: base64String) {
                let tmpFileURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("genAudio").appendingPathExtension("wav")
                
                let wasFileWritten = (try? convertedData.write(to: tmpFileURL, options: [.atomic])) != nil
                if wasFileWritten {
                    DispatchQueue.main.async {
                        do {
                            let player = try AVAudioPlayer(contentsOf: tmpFileURL)
                            print("Save file at \(tmpFileURL.path())")
                            self.audioGeneratedPlayer = player
                            self.loadingState = .audioGenerated

                        } catch {
                            print("player failed to load")
                            print(error)
                        }
                        
                    }
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.serverState = .noServer
            print("did complete \(error)")
        }
    }
    
    /// - URLSessionDelegate
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("Session invalid \(String(describing:error))")
    }
}

