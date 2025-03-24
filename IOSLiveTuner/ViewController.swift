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

  var avPlayer: AVAudioPlayer?
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

  var selectedAudioFile = ""

  required init?(coder decoder: NSCoder) {

    let path = Bundle.main.path(forResource: "piano.m4a", ofType: nil)!
    let url = URL(fileURLWithPath: path)

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

    do {
      avPlayer = try AVAudioPlayer(contentsOf: url)
      avPlayer?.numberOfLoops = -1
    } catch {
      print("Could not load file")
      return
    }

    engine.output = silence
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
        let noteFrequencies = [
          16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87,
        ]
        let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

        guard amp > 0.1 else { return }

        var freq = pitch

        while freq > Float(noteFrequencies[noteFrequencies.count - 1]) {
          freq = freq / 2.0
        }

        while freq < Float(noteFrequencies[0]) {
          freq = freq * 2.0
        }

        var minDistance: Float = 10000.0

        var index = 0

        for j in 0..<noteFrequencies.count {
          let distance = fabsf(Float(noteFrequencies[j]) - freq)
          if distance < minDistance {
            index = j
            minDistance = distance
          }
        }

        var refNoteSameOct = noteFrequencies[index]
        var lastNoteSameOct = noteFrequencies[noteFrequencies.count - 1]
        var pitchPrecise = Double(pitch)

        while pitchPrecise > lastNoteSameOct {
          lastNoteSameOct = lastNoteSameOct * 2

          refNoteSameOct = refNoteSameOct * 2
        }

        var cents = Int(round(1200 * log2(pitchPrecise / refNoteSameOct)))

        var centsStr = ""
        if cents < 0 {
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

        // The needle stays within +/- 50 degrees
        self.moveNeedleTo(degrees: Double(cents))
      }
    }

    tracker.start()

//    var session = AVAudioSession.sharedInstance()
//    do {
//      try session.setCategory(.playAndRecord)
//      try session.setActive(true)
//    } catch {
//      print("Could not set session category")
//      return
//    }

    do {
      try engine.start()
    } catch {
      print("Engine failed")
    }

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

  override func viewDidLoad() {
    super.viewDidLoad()

    displayAudioFiles()
  }


  @IBAction func playAudio() {
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
    print(action.title)
    let alreadyPlaying = avPlayer!.isPlaying

    avPlayer?.stop()

    avPlayer = nil

    let audioFileName = action.title + ".m4a"
    let path = Bundle.main.path(forResource: audioFileName, ofType: nil)!
    let url = URL(fileURLWithPath: path)

    do {
      avPlayer = try AVAudioPlayer(contentsOf: url)
      avPlayer?.numberOfLoops = -1

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
