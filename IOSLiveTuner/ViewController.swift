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
import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var pitchLbl: UILabel!
  @IBOutlet weak var centsLbl: UILabel!
  @IBOutlet weak var playPauseBtn: UIButton!
  @IBOutlet weak var noteNameBtn: UIButton!
  @IBOutlet weak var audioFileBtn: UIButton!

  @IBOutlet var menuBtn: UIButton!

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

  let defaultAudioFile = "C4"
  var selectedAudioFile = ""

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
      
      let path = Bundle.main.path(forResource: defaultAudioFile + ".m4a", ofType: nil)!
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
            var pitch = p[0]
            var amp = a[0]
            
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
            
            
            let centsStr = "\(cents)"

            self.pitchLabelStr = transposedNoteBb

            self.pitchLbl.text = transposedNoteBb

            self.centsLbl.text = centsStr
            self.centsLabelStr = centsStr

            // The needle stays within +/- 50 degrees
            self.moveNeedleTo(degrees: Double(cents))
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

    displayAudioFiles()
  }


  @IBAction func playAudio() {
      print("Engine is running before playback: ")
      print(engine.avEngine.isRunning)
      if (!engine.avEngine.isRunning){
          do{
              try engine.start()
          } catch {
              print("Can't start engine in playAudio")
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


  func switchAudio(action: UIAction) {
      print("Switching audio")
    print(action.title)
    let alreadyPlaying = avPlayer?.isPlaying ?? false

    avPlayer?.stop()

    avPlayer = nil

    let audioFileName = action.title + ".m4a"
    let path = Bundle.main.path(forResource: audioFileName, ofType: nil)!
    let url = URL(fileURLWithPath: path)

    do {
        avPlayer = try AudioPlayer()
        try avPlayer?.load(url: url, buffered: true)
        avPlayer?.isLooping = true
        engine.stop()
        engine.output = Mixer(Fader(mic, gain: 0), avPlayer!)
        try engine.start()
        
      if alreadyPlaying {
        avPlayer?.play()
      }
    } catch {
      print("Error setting audio player to new file: \(error)")
    }

  }

  func displayAudioFiles() {
    let noteNames = getAllAudioFiles()

    var menuChildren: [UIMenuElement] = []

    for file in noteNames {
      let audioName = removeAudioFileType(filename: file)
      if selectedAudioFile == "" {
        selectedAudioFile = file
        menuChildren.append(UIAction(title: audioName, state: .on, handler: switchAudio))
      } else {
        menuChildren.append(UIAction(title: audioName, handler: switchAudio))

      }
    }

    audioFileBtn.menu = UIMenu(options: .displayInline, children: menuChildren)
    audioFileBtn.showsMenuAsPrimaryAction = true
    audioFileBtn.changesSelectionAsPrimaryAction = true

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
