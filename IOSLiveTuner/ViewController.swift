//
//  ViewController.swift
//  IOSLiveTuner
//
//  Created by Auburn University Student on 2/21/25.
//

import AVFoundation
import AudioKit
import AudioKitEX
import AudioKitUI
import AudioToolbox
import CoreAudio
import CoreAudioKit
import SoundpipeAudioKit
import UniformTypeIdentifiers
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var pitchLbl: UILabel!
    @IBOutlet weak var centsLbl: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    
    @IBOutlet weak var noteOctBtn: UIButton!
    @IBOutlet weak var noteNameBtn: UIButton!
    
    
    var avPlayer: AudioPlayer?
    var engine = AudioEngine()
    var tappableNodeA: Fader
    var tappableNodeB: Fader
    var tappableNodeC: Fader
    var tracker: PitchTap!
    var mic: AudioEngine.InputNode
    let initialDevice: Device
    let silence: Fader
    
    @Published var pitchLabelStr = "_"
    @Published var centsLabelStr = "-"
    
    @IBOutlet weak var animateBtn: UIButton!
    @IBOutlet weak var tunerNeedle: UIImageView!
    
    var rotated = false
    var setAnchor = false
    
    let defaultNote = "C"
    let defaultOct = "4"
    
    required init?(coder decoder: NSCoder) {
        
        
        // Set up mic
        guard let input = engine.input else { fatalError() }
        guard let device = engine.inputDevice else { fatalError() }
        
        initialDevice = device
        
        mic = input
        tappableNodeA = Fader(mic)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        
        silence = Fader(tappableNodeC, gain: 0)
        
        
        super.init(coder: decoder)
        
    }
    
    func moveNeedleTo(degrees: Double) {
        let radians = degrees * .pi / 180.0
        if tunerNeedle.image?.cgImage == nil {
            print("Image or CGImage is nil")
            return
        }
        
        let viewHeight = tunerNeedle.bounds.height
        
        if !setAnchor {
            tunerNeedle.anchorPoint = CGPointMake(0.5, 1)
            setAnchor = true
        }
        
        if !rotated {
            
            self.tunerNeedle.transform = CGAffineTransformMakeTranslation(0, viewHeight / 2.0).rotated(
                by: radians)
            rotated = true
        } else {
            self.tunerNeedle.transform = CGAffineTransformMakeRotation(0).translatedBy(
                x: 0, y: viewHeight / 2.0)
            rotated = false
            
        }
        
    }
    
    
    func removeAudioFileType(filename: String) -> String {
        return (filename as NSString).deletingPathExtension
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let path = Bundle.main.path(forResource: defaultNote + defaultOct + ".m4a", ofType: nil)!
        let url = URL(fileURLWithPath: path)
        
        do {
            avPlayer = try AudioPlayer()
            try avPlayer?.load(url: url, buffered: true)
            avPlayer?.isLooping = true
            engine.output = Mixer(Fader(mic, gain: 0), avPlayer!)
            print("Engine is started after output: ")
            print(engine.avEngine.isRunning)
        } catch {
            print("Could not load file: \(error)")
            return
        }
        
        do {
            try Settings.setSession(category: .playAndRecord, with: [.allowBluetoothA2DP])
            var availableInputs = AVAudioSession.sharedInstance().availableInputs
            if let builtInMic = availableInputs?.first(where: { $0.portType == .builtInMic }) {
                try AVAudioSession.sharedInstance().setPreferredInput(builtInMic)
                print("Switched to internal microphone")
            }
        } catch {
            print("Failed to set AudioKit settings")
            return
        }
        
        tracker = PitchTap(mic) { p, a in
            DispatchQueue.main.async {
                self.handlePitch(pitch: p[0], amp: a[0])
            }
        }
        
        tracker.start()
        
        do {
            try engine.start()
            print("Engine is started: ")
            print(engine.avEngine.isRunning)
        } catch {
            print("Engine failed")
        }
        
        displayNoteNames()
        displayOctaves()
        
    }
    
    
    func handlePitch(pitch: Float, amp: Float){
        // Check that the pitch is not simply background noise
        guard amp > 0.12 else {return}
        
        // Calculate the MIDI musical number based on a reference pitch (A4 = 440 hz)
        let midiDouble = 12 * log2(pitch / 440.0) + 69
        let midiNum = Int(round(midiDouble))
        
        
        let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
        
        
        let noteNameConcertPitch = noteNamesWithFlats[midiNum % 12]
        let octaveConcertPitch = (midiNum / 12) - 1
        
        // The closest pitch on a piano in hertz
        let concertPitchFreq = Float(pow(2.0, Double(midiNum - 69) / 12.0) * 440.0)
        
        // Calculate cents (deviation of played note from the key on a piano)
        // Cents show slight variations between the played pitch and the closest pitch on the piano
        let divideConcertPitch = pitch / concertPitchFreq
        let cents = Int(round(1200 * log2(divideConcertPitch)))
        
        
        
        // The transposed note on a Bb instrument
        let midiNumBb = midiNum + 2
        let transposedNoteBb = noteNamesWithFlats[midiNumBb % 12]
        let octaveBb = (midiNumBb / 12) - 1
        
        
        let centsStr = "\(cents)¢"
        
        self.pitchLabelStr = transposedNoteBb
        
        self.pitchLbl.text = transposedNoteBb
        
        self.centsLbl.text = centsStr
        self.centsLabelStr = centsStr
        
        // The needle stays within +/- 50 degrees
        self.moveNeedleTo(degrees: Double(cents))
    }
    
    
    @IBAction func playPausePressed() {
        print("Engine is running before playback: ")
        print(engine.avEngine.isRunning)
        if (!engine.avEngine.isRunning){
            do{
                try engine.start()
            } catch {
                print("Can't start engine in playPausePressed")
            }
        }
        if avPlayer?.isPlaying != nil && avPlayer!.isPlaying {
            avPlayer?.pause()
            playPauseBtn.setImage(UIImage(systemName: "play.fill"), for: UIControl.State.normal)
        } else {
            
            avPlayer?.play()
            playPauseBtn.setImage(UIImage(systemName: "pause.fill"), for: UIControl.State.normal)
        }
        
        print(engine.inputDevice)
        print(engine.outputDevice)
    }
    
    @IBAction func onNoteChange(sender: Any) {
        print("Note changed")
        //        print(sender)
        //        print(noteNameBtn.menu)
        //        print(noteNameBtn.menu?.selectedElements)
    }
    
    
    
    
    
    func displayNoteNames() {
        let noteNames = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
        
        var menuChildren: [UIMenuElement] = []
        
        for n in noteNames {
            if n == defaultNote {
                menuChildren.append(UIAction(title: n, state: .on, handler: switchAudio))
            } else {
                menuChildren.append(UIAction(title: n, handler: switchAudio))
                
            }
        }
        
        noteNameBtn.menu = UIMenu(options: .displayInline, children: menuChildren)
        noteNameBtn.showsMenuAsPrimaryAction = true
        noteNameBtn.changesSelectionAsPrimaryAction = true
        
        
    }
    
    func displayOctaves() {
        let labels = ["3", "4", "5", "6"]
        
        var menuChildren: [UIMenuElement] = []
        
        for l in labels {
            if l == defaultOct {
                menuChildren.append(UIAction(title: l, state: .on, handler: switchAudio))
            } else {
                menuChildren.append(UIAction(title: l, handler: switchAudio))
                
            }
        }
        
        noteOctBtn.menu = UIMenu(options: .displayInline, children: menuChildren)
        noteOctBtn.showsMenuAsPrimaryAction = true
        noteOctBtn.changesSelectionAsPrimaryAction = true
        
        
    }
    
    func switchAudio(action: UIAction) {
        let note = noteNameBtn.menu!.selectedElements[0].title
        let oct = noteOctBtn.menu!.selectedElements[0].title
        
        let alreadyPlaying = avPlayer?.isPlaying ?? false
        // Verify that the selected not is in the instrument's range
        print(isNoteValid(note: note, octaveStr: oct))
        if (!isNoteValid(note: note, octaveStr: oct)){
            if(alreadyPlaying){
                print("Paused audio")
                playPausePressed()
            }
            print("Invalid Note Selected")
            return
        }
    
        let audioFileName = note + oct + ".m4a"
        print("Continuing with file " + audioFileName)
        
          if (alreadyPlaying){
              playPausePressed()
          }
          avPlayer?.stop()
          let path = Bundle.main.path(forResource: audioFileName, ofType: nil)!
          let url = URL(fileURLWithPath: path)
    
          do {
              try avPlayer?.load(url: url)
          } catch {
              print("Error during audio file switch: \(error)")
          }
    
          if alreadyPlaying {
              playPausePressed()
          }
        
    }
    
    func isNoteValid(note: String, octaveStr: String) -> Bool {
        guard let octave = Int(octaveStr) else {
            return false
        }
        if (octave < 3 || octave > 6){
            return false
        }
        let validNotes = ["Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B", "C"]
        
        if !validNotes.contains(note){
            return false
        }
        
        if octave == 3 && (validNotes.firstIndex(of: note)! < 3 || validNotes.firstIndex(of: note) == validNotes.count - 1){
            // Too low for clarinet
            return false
        }
        if octave == 6 && validNotes.firstIndex(of: note)! > 8 {
            // Too high for clarinet
            return false
        }
        
        return true
    }
    
    func getAllAudioFiles() -> [String] {
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!
        var audioNames: [String] = []
        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            for i in items {
                if i.hasSuffix(".m4a") {
                    audioNames.append(i)
                }
            }
            
            
        } catch {
            print("Error getting audio files: \(error)")
        }
        
        return audioNames
    }
    
}
