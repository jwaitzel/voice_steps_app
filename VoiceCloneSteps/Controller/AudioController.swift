//
//  AudioController.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/18/24.
//

import SwiftUI
import AVFoundation

struct Recording {
    let fileURL: URL
    let createdAt: Date
    let player: AVPlayer
}

//MARK: Audio Controller
class AudioController: NSObject, ObservableObject {
    
    static var shared: AudioController = .init()
    
    var recorder: AVAudioRecorder!
    
    @Published var isRecording: Bool = false
    @Published var recordings = [Recording]()
    @Published var recordingFileURL: URL?

    @Published var player: AVAudioPlayer?
    @Published var isPlaying: Bool = false

    @Published var midBarFrameIdx: Int = 41 // start at middle
    @Published var barFrequencyValues = Array(repeating: 0.01, count: 84)

    @Published var animateListening: Bool = false

    private var meterDisplayLink: CADisplayLink?

    private var didSetupRecorder = false
    
    var startRecordingDate: Date?
    @Published var secondsPassed: CGFloat = 0.0
    @Published var totalRecordTime: CGFloat = 0.0

    //MARK: Setup AVRecorder
    func setupRecorder() {
        setupAudioSession()
        enableBuiltInMic()
        setupFileAndRecorder()
        didSetupRecorder = true
    }

    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            fatalError("Failed to configure and activate session.")
        }
    }
    
    private func enableBuiltInMic() {
        // Get the shared audio session.
        let session = AVAudioSession.sharedInstance()
        
        // Find the built-in microphone input.
        guard let availableInputs = session.availableInputs,
              let builtInMicInput = availableInputs.first(where: { $0.portType == .builtInMic }) else {
            print("The device must have a built-in microphone.")
            return
        }
        
        // Make the built-in microphone input the preferred input.
        do {
            try session.setPreferredInput(builtInMicInput)
            print("Enabled mic")
        } catch {
            print("Unable to set the built-in mic as the preferred input.")
        }
    }

    func setupFileAndRecorder() {
        
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = tempDir.appendingPathComponent("recording.wav")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }

        do {
            if FileManager.default.fileExists(atPath: fileURL.path()) {
                try FileManager.default.removeItem(at: fileURL)
                print("removing file")
            }

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
//                AVLinearPCMIsNonInterleaved: false,
                AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1,
//                AVSampleRateKey: 44_100.0,
//                AVNumberOfChannelsKey: isStereoSupported ? 2 : 1,
//                AVLinearPCMBitDepthKey: 16
            ]
            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            print("Created recorder")
        } catch {
            fatalError("Unable to create audio recorder: \(error.localizedDescription)")
        }
        
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()

    }
    
    /// - Audios Folder
    func audiosDirectory() -> URL {
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let docDirectory = path.appending(path: "audios", directoryHint: .isDirectory)
        if !FileManager.default.fileExists(atPath: docDirectory.path(), isDirectory: nil) {
            try! FileManager.default.createDirectory(at: docDirectory, withIntermediateDirectories: true)
            print("Created dictory")
        }
        return docDirectory
    }
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
//        var formarString: String = "yyyy-MM-dd HH:mm:ss +zzzz"
//        dateFormatter.dateFormat = formarString
        dateFormatter.timeStyle = .long
        dateFormatter.dateStyle = .none
        return dateFormatter
    }()
    
    func startStopRecodingAction() {
        if isRecording {
            stopRecording()
            return
        }
        
        if !didSetupRecorder {
            setupRecorder()
        }

        startRecordingDate = Date()
        installDisplayLink()

        recorder.record()
        isRecording = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            animateListening = true
        }
    }
    
    func stopRecording() {
        isRecording = false
        recorder.stop()//Stop and close
        uninstallDisplayLink()

        /// - Animations for stopping
        animateStopBars()
    }
    
    func animateStopBars() {
        withAnimation(.easeInOut(duration: 1.0)) {
            for i in 0...midBarFrameIdx {
                self.barFrequencyValues[i] = 0.01
            }
        }
    }
    
    fileprivate func installDisplayLink() {
        meterDisplayLink = CADisplayLink(target: self, selector: #selector(updateMeter))
        meterDisplayLink?.preferredFramesPerSecond = 20
        meterDisplayLink?.add(to: .current, forMode: .common)
    }
    
    fileprivate func uninstallDisplayLink() {
        if let displayLink = meterDisplayLink {
            displayLink.remove(from: .current, forMode: .common)
            displayLink.invalidate()
            meterDisplayLink = nil
        }
    }
    
    //MARK: Update monitor
    @objc
    private func updateMeter() {

        var loudValue = 0.0 //scaledValue(Double(avgVal))
        if isPlaying {
            player?.updateMeters()
            let avgVal = player?.averagePower(forChannel: 0) ?? 0
            loudValue = scaledValue(Double(avgVal))
            
            secondsPassed = player?.currentTime ?? 0
        } else {
            recorder.updateMeters()
            let avgVal = recorder.averagePower(forChannel: 0)
            loudValue = scaledValue(Double(avgVal))
            
            secondsPassed = Date().timeIntervalSince(self.startRecordingDate ?? Date())

        }
        
        let transformedLevel = loudValue //CGFloat.random(in: 0...1.0)
        let midIndex = midBarFrameIdx+1
        barFrequencyValues.insert(transformedLevel, at: midIndex)
        barFrequencyValues.remove(at: 0)
        
    }


    
    func stopPlayer() {
        player?.stop()
        isPlaying = false
        uninstallDisplayLink()
        animateStopBars()
        secondsPassed = 0
        player?.currentTime = 0.0
    }
    
    func startStopAudioPlayer() {
        guard let player else { print("No player"); return; }
        if isPlaying {
            stopPlayer()
            return
        }
        
        installDisplayLink()
        
//
        player.isMeteringEnabled = true
        isPlaying = true
        
        DispatchQueue.main.async {
            player.play()
        }
    }
    
    
    func deleteRecording() {
        recorder.deleteRecording()
        if isPlaying {
            self.startStopAudioPlayer()
        }
        player = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            animateListening = false
        }
    }
    
    /// - Debug fetch all recordings
    func fetchAllRecording(){
            
        let directoryPath = audiosDirectory()
        let directoryContents = try! FileManager.default.contentsOfDirectory(at: directoryPath, includingPropertiesForKeys: nil)

        var newRecordings = [Recording]()
//        recordings.removeAll()
        for fileURL in directoryContents {
//            print(i)
            let fullString = (fileURL.lastPathComponent as NSString).deletingPathExtension
            let fileDate = dateFormatter.date(from: fullString) ?? .now
            let player = AVPlayer(url: fileURL)
            let record = Recording(fileURL : fileURL, createdAt: fileDate, player: player)
            newRecordings.append(record)
//            recordings.append(record)
        }
            
        newRecordings.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending})
        
//        print("Updated recordings \(newRecordings)")
        DispatchQueue.main.async {
            self.recordings = newRecordings
        }
    }


}

extension AudioController: AVAudioRecorderDelegate {
    
    // The AVAudioRecorderDelegate method.
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        let pathDirectory = audiosDirectory()
        let fileDateStr = dateFormatter.string(from: Date())
        let destURL = pathDirectory.appending(path: "\(fileDateStr).wav")

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: recorder.url, to: destURL)

            if flag {
               print("Saved record successfully")
                fetchAllRecording()
                player = try AVAudioPlayer(contentsOf: destURL)
                player?.delegate = self
                player?.prepareToPlay()
                recordingFileURL = destURL
                totalRecordTime = secondsPassed
            }

        } catch {
            print("Failed to copy file")
        }
        
    }
}

extension AudioController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlayer()
    }
}
