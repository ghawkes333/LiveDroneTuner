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

    
    var avPlayer : AVAudioPlayer?
    var engine = AudioEngine()
    var tappableNodeA : Fader
    var tappableNodeB : Fader
    var tappableNodeC : Fader
    var tracker: PitchTap!
    var mic: AudioEngine.InputNode
    let initialDevice: Device
    let silence: Fader
    
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
        
        tracker = PitchTap(mic) {pitch, amp in DispatchQueue.main.async {
                    print(pitch[0])
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

    
    
}
