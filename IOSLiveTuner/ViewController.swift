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



import UIKit

class ViewController: UIViewController {

    let engine = AudioEngine()
    var player = AudioPlayer()
    
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
                    
        guard let urlString = Bundle.main.path(forResource: "theme", ofType: "mp3") else {
            print("Could not retrieve URL string")
            return
        }
        
        player = AudioPlayer(url: URL(fileURLWithPath: urlString), buffered: true)!
            
        
    }
    
    func getFileURL() -> URL {
        let name = "theme.mp3"
        let url = URL(fileURLWithPath: name)
        
        return url
    }
    
    @IBAction func startPlaying(){
        do {
            engine.output = player
            try engine.start()
            player.isLooping = true
            player.start()
        }catch {
            print("Could not start engine")
            return
        }
    }
    
    func repeatFile(){
        print("Repeating...")
    }
    

    
    
}
