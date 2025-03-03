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
    
    var avPlayer : AVAudioPlayer?
    var engine = AudioEngine()
    var tappableNodeA : Fader
    var tappableNodeB : Fader
    var tappableNodeC : Fader
    var tracker: PitchTap!
    var mic: AudioEngine.InputNode
    let initialDevice: Device
    let silence: Fader
    
    @Published var pitchLabelStr = "_"

    
    required init?(coder decoder: NSCoder) {
        
                
        let path = Bundle.main.path(forResource: "theme.mp3", ofType: nil)!
        let url = URL(fileURLWithPath: path)
        

        
        
        
        // Set up mic
        guard let input = engine.input else{fatalError()}
        guard let device = engine.inputDevice else {fatalError()}
                
        initialDevice = device
        
        mic = input
        tappableNodeA = Fader(mic)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        
        silence = Fader(tappableNodeC, gain: 0)
        
        
        super.init(coder: decoder)
        
//        pitchLbl.text = "Yay!"

        
        do {
            avPlayer = try AVAudioPlayer(contentsOf: url)
            avPlayer?.numberOfLoops = -1
            avPlayer?.play()
            print("Playing...")
        } catch {
            print("Could not load file")
            return
        }
        
    
        engine.output = silence
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
            
            guard amp > 0.1 else {print("Amp: ", amp); return}
            
            print("Success!")
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
            
            let octave = Int(log2f(pitch / freq))
    
            var noteNameWithSharps = "\(noteNamesWithSharps[index])\(octave)"
            var noteNameWithFlats = "\(noteNamesWithFlats[index])\(octave)"
    
            print(noteNameWithFlats)
            self.pitchLabelStr = noteNameWithFlats
            self.pitchLbl.text = noteNameWithFlats
        }}
        
        tracker.start()
        
        var session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord)
            try session.setActive(true)
        } catch {
            print("Could not set session category")
            return
        }
        
        
        
        do{
            try engine.start()
            print("Started")
        } catch {
            print("Engine failed")
        }
        
        
    }
    
    
    @IBAction func checkPitches(){
        tracker.start()
    }
    
    func freqToPitch(pitch : Float, amp : Float){
        
//        let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
//        let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
//        let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
        
//        guard amp > 0.1 else {print("Amp: ", amp); return}
        
//        print("Success!")
//        var freq = pitch
//        
//        while freq > Float(noteFrequencies[noteFrequencies.count - 1]){
//            freq = freq / 2.0
//        }
//        
//        while freq < Float(noteFrequencies[0]){
//            freq = freq * 2.0
//        }
        
//        var minDistance: Float = 10000.0
//        
//        var index = 0
//        
//        for j in 0 ..< noteFrequencies.count {
//            let distance = fabsf(Float(noteFrequencies[j]) - freq)
//            if distance < minDistance {
//                index = j
//                minDistance = distance
//            }
//        }
        
//        let octave = Int(log2f(pitch / freq))
//        
//        var noteNameWithSharps = "\(noteNamesWithSharps[index])\(octave)"
//        var noteNameWithFlats = "\(noteNamesWithFlats[index])\(octave)"
//        
//        print(noteNameWithFlats)
//        pitchLbl.text = noteNameWithFlats
        
        
        
    }

    
    
}
