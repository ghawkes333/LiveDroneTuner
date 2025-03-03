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

    let engine = AudioEngine()
    var player = AudioPlayer()
    var tappableNodeA : Fader
    var tappableNodeB : Fader
    var tappableNodeC : Fader
    var tracker: PitchTap!
    var mic: AudioEngine.InputNode
    
    var testNode : Fader
    
    let initialDevice: Device
    
    
    let silence: Fader
    
    
    
    
    required init?(coder decoder: NSCoder) {
        guard let input = engine.input else {fatalError()}
        guard let device = engine.inputDevice else {fatalError()}
        
        initialDevice = device
        
        mic = input
        tappableNodeA = Fader(mic)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        
        silence = Fader(tappableNodeC, gain: 0)
        
        testNode = Fader(mic) // Test
        
        
        
//        engine.output = testNode
        super.init(coder: decoder)
        
        
        guard let urlString = Bundle.main.path(forResource: "theme", ofType: "mp3") else {
        print("Could not retrieve URL string")
        return
        }
        player = AudioPlayer(url: URL(fileURLWithPath: urlString), buffered: true)!
        
        engine.output = silence
        
        tracker = PitchTap(mic) {pitch, amp in DispatchQueue.main.async {
            // Are other indicies applicable? Average them?
            print("Got pitch!")
            print(pitch[0])
//            print(pitch[0], amp[0])
        }}
        
        tracker.start()
        
        var session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord)
//            try session.setCategory(.playAndRecord, options: [.allowBluetoothA2DP])
            try session.setPreferredIOBufferDuration(Settings.bufferLength.duration)
            try session.setActive(true)
        } catch {
            print("Could not set session category")
            return
        }
        
        
        
        do {
            try engine.start()
        }catch {
            print("Could not start engine")
            return
        }
        
        
        // Remember - don't change engine settings after it is started

        
        
        
//        do{
//            var d = AudioEngine.inputDevices[0]
//            print(AudioEngine.inputDevices)
//            print("Choosing", d)
//            try AudioEngine.setInputDevice(d)
//        } catch {
//            print("Error setting AudioEngine input device")
//        }
        
    }

    
    func getFileURL() -> URL {
        let name = "theme.mp3"
        let url = URL(fileURLWithPath: name)
        
        return url
    }
    
    @IBAction func startPlaying(){
        do {
//            engine.output = player
            player.isLooping = true
            player.start()
        }catch {
            print("Could not start engine")
            return
        }
    }
    
    @IBAction func checkPitches(){
        tracker.start()
    }
    
    func repeatFile(){
        print("Repeating...")
    }
    

    
    
}
