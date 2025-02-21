//
//  ViewController.swift
//  IOSLiveTuner
//
//  Created by Auburn University Student on 2/21/25.
//

import AVFoundation

var player : AVAudioPlayer?

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var button : UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("Ran")
    }
    
    @IBAction func didTapButton() {
        
        print("Tap!")
        
        
        if let player = player, player.isPlaying {
            // Stop playback
            button.setTitle("Play", for: .normal)
            player.stop()
        } else {
            button.setTitle("Stop", for: .normal)
            print("Setting up audio")
            // Set up player and play
            let urlString = Bundle.main.path(forResource: "theme", ofType: "mp3")
            print(urlString)
            do {
                try AVAudioSession.sharedInstance().setMode(.default)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                
                // This line ensures that the audio plays even when the phone is on "silent"
                try AVAudioSession.sharedInstance().setCategory(.playback)
                guard let urlString = urlString else {
                    print("Mmmm urlString isn't define")
                    return
                }
                print("urlstring success")
                
            
                player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: urlString))
                
                guard let player = player else {
                    print("Player isn't defined")
                    return
                }
                
                // Loop indefinitely
                player.numberOfLoops = -1
                print("player success")
                player.play()
                print("playing")
                    
                                           
                                        
            } catch{
                print("Error when attempting to play audio")
            }
        }
        
    }


}

