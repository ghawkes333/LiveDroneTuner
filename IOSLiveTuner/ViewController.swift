//
//  ViewController.swift
//  IOSLiveTuner
//
//  Created by Auburn University Student on 2/21/25.
//

import AVFoundation
import CoreAudioKit
import AudioKit
import AudioKitEX
import AudioKitUI
import AudioToolbox
import SoundpipeAudioKit

import CoreAudio



import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var pitchLbl: UILabel!
    @IBOutlet weak var centsLbl: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    
    var avPlayer : AVAudioPlayer?
    
    let playerEngine : AVAudioEngine
    var audioFile = AVAudioFile()
    var avPlayerNode = AVAudioPlayerNode()
    var buffer : AVAudioPCMBuffer
    
    var micEngine = AudioEngine()
    var tappableNodeA : Fader
    var tappableNodeB : Fader
    var tappableNodeC : Fader
    var tracker: PitchTap!
    var mic: AudioEngine.InputNode
    let initialDevice: Device
    let silence: Fader
    
    @Published var pitchLabelStr = "_"
    @Published var centsLabelStr = "-"
    
    
    required init?(coder decoder: NSCoder) {
        
        
        let path = Bundle.main.path(forResource: "Dummy_file_cropped.m4a", ofType: nil)!
        let url = URL(fileURLWithPath: path)
        
        // Set up mic
        guard let input = micEngine.input else{fatalError()}
        guard let device = micEngine.inputDevice else {fatalError()}
        
        initialDevice = device
        
        playerEngine = AVAudioEngine()
        mic = input
        tappableNodeA = Fader(mic)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        
        buffer = AVAudioPCMBuffer()
        
        silence = Fader(tappableNodeC, gain: 0)

        
        super.init(coder: decoder)
        
        
    
        
        do {
            let file = try AVAudioFile(forReading: url)
            guard let b = try AVAudioPCMBuffer(file: file) else {
                print("Could not get Audio buffer");
                return
            }
            buffer = b
            try audioFile = AVAudioFile(forReading: url)
//            try audioFile.read(into:/* */buffer)
            playerEngine.attach(avPlayerNode)
            
            playerEngine.connect(avPlayerNode, to: playerEngine.mainMixerNode, format: AVAudioFormat.init(standardFormatWithSampleRate: 48000, channels: 1))
            avPlayerNode.scheduleBuffer(buffer, at: nil, options: .loops)
            
            try playerEngine.start()
            
//            avPlayer = try AVAudioPlayer(contentsOf: url)
//            avPlayer?.numberOfLoops = -1
//            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowBluetoothA2DP, .mixWithOthers])
        } catch {
            print("Could not set up AVF Audio")
            return
        }
        
        
        micEngine.output = silence
        do{
            try Settings.setSession(category: .playAndRecord)
        } catch {
            print("Failed to set AudioKit settings")
            return
        }
        
        tracker = PitchTap(mic) {p, a in DispatchQueue.main.async {
            var pitch = p[0]
            var amp = a[0]
            let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
            let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
            let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
            
            guard amp > 0.1 else {return}
            
            var freq = pitch
            
            while freq > Float(noteFrequencies[noteFrequencies.count - 1]){
                freq = freq / 2.0
            }
            
            while freq < Float(noteFrequencies[0]){
                freq = freq * 2.0
            }
            
            var minDistance: Float = 10000.0
            
            var index = 0
            
            for j in 0 ..< noteFrequencies.count {
                let distance = fabsf(Float(noteFrequencies[j]) - freq)
                if distance < minDistance {
                    index = j
                    minDistance = distance
                }
            }
            
            var refNoteSameOct = noteFrequencies[index]
            var lastNoteSameOct = noteFrequencies[noteFrequencies.count - 1]
            var pitchPrecise = Double(pitch)
            
            while (pitchPrecise > lastNoteSameOct){
                lastNoteSameOct = lastNoteSameOct * 2
                
                refNoteSameOct = refNoteSameOct * 2
            }
            
            
            var cents = Int(round(1200 * log2(pitchPrecise / refNoteSameOct)))
            
            var centsStr = ""
            if (cents < 0){
                centsStr = "\(cents)"
            } else {
                centsStr = "+\(cents)"
            }
            
            let octave = Int(log2f(pitch / freq))
            
            var noteNameWithSharps = "\(noteNamesWithSharps[index])\(octave)"
            var noteNameWithFlats = "\(noteNamesWithFlats[index])\(octave)"
            
            self.pitchLabelStr = noteNameWithFlats
            
            self.pitchLbl.text = noteNameWithFlats
            
            self.centsLbl.text = centsStr
            self.centsLabelStr = centsStr
        }}
        
        tracker.start()
        
        
        
        
        do{
            try micEngine.start()
        } catch {
            print("Engine failed")
        }
        
        
    }
    
    @IBAction func playAudio(){
//        if (avPlayer?.isPlaying != nil && avPlayer!.isPlaying){
//            avPlayer?.pause()
//            playPauseBtn.setImage(UIImage(systemName: "play.fill"), for: UIControl.State.normal)
//        } else {
//            avPlayer?.play()
//            playPauseBtn.setImage(UIImage(systemName: "pause.fill"), for: UIControl.State.normal)
//        }
        print(avPlayerNode.isPlaying)
            if (avPlayerNode.isPlaying){
            avPlayerNode.pause()
            playPauseBtn.setImage(UIImage(systemName: "play.fill"), for: UIControl.State.normal)
        } else {
            avPlayerNode.play()
            playPauseBtn.setImage(UIImage(systemName: "pause.fill"), for: UIControl.State.normal)
        }
    }
    
    

    
    
}
