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

var player : AVAudioPlayer?


import UIKit

class ViewController: UIViewController {
    
    
    var engine = AudioEngine()
    var initialDevice: Device
    var mic: AudioEngine.InputNode
    var tappableNodeA: Fader
    
    var tracker: PitchTap!

    
    required init?(coder decoder: NSCoder) {

        guard let input = engine.input else { fatalError() }

        guard let device = engine.inputDevice else { fatalError() }

        
        
        self.initialDevice = device
        self.mic = input
        tappableNodeA = Fader(mic)
        
        do{
            
            let silence = Fader(self.engine.input!, gain: 0)
            self.engine.output = silence
        } catch{
            print("Error!")
        }

        
        super.init(coder: decoder)
        
        
        
        tracker = PitchTap(mic) {pitch, amp in DispatchQueue.main.async {
            print("Pitch: ")
            print(pitch[0])
            
        }}
    
        self.tracker.start()
    
        startAudioEngine()
        
        print("Tracking started")
    }
    
    
    @IBOutlet var button : UIButton!
    @IBOutlet var recBtn : UIButton!
    
    let captureSession = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapButton() {
        print("starting mic")
        mic.start()
//        engine.start()
        print("Mic started")
        print(tracker.amplitude)
        print("Amp is above")
        
        if let player = player, player.isPlaying {
            // Stop playback
            button.setTitle("Play", for: .normal)
            player.stop()
        } else {
            button.setTitle("Stop", for: .normal)
            // Set up player and play
            let urlString = Bundle.main.path(forResource: "theme", ofType: "mp3")
            do {
                try AVAudioSession.sharedInstance().setMode(.default)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                
                // This line ensures that the audio plays even when the phone is on "silent"
                try AVAudioSession.sharedInstance().setCategory(.playback)
                guard let urlString = urlString else {
                    return
                }
                
                player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: urlString))
                
                guard let player = player else {
                    return
                }
                
                // Loop indefinitely
                player.numberOfLoops = -1
                player.play()
                
                
                
            } catch{
                print("Error when attempting to play audio")
            }
        }
    }
    
    func startAudioEngine(){
        do{
            try engine.start()
        } catch {
            print("Failed to start audio engine \(error)")
        }
    }
        
        @IBAction func checkPitch(){
            mic.start()
            print("Checking...")
            print(tracker.leftPitch)
            print(tracker.rightPitch)
        }
        
        func initAudioSession() {
            
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
        
            
        }
        
        
        func update(p : String, a : String){
            print("Pitch and amp are: ")
            print(p)
            print(a)
        }

    
    
    
}
