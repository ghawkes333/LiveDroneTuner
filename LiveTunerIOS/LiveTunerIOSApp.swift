//
//  LiveTunerIOSApp.swift
//  LiveTunerIOS
//
//  Created by Auburn University Student on 2/17/25.
//

import SwiftUI
import AVFAudio

@main
struct LiveTunerIOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
//            print("Setting audio")
            
//            setupAudioSession()
//            print("audio set")
            
            Button("Record", systemImage: "arrow.up", action: hi_world)
        }

    }
   
    func hi_world(){
        print("helloooo aliens")
    }
    
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            fatalError("Failed to configure and activate session.")
        }
    }
    
}


//func init() {
//
//    var status: OSStatus
//
//    do {
//        try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(preferredIOBufferDuration)
//    } catch let error as NSError {
//        print(error)
//    }
//
//
//    var desc: AudioComponentDescription = AudioComponentDescription()
//    desc.componentType = kAudioUnitType_Output
//    desc.componentSubType = kAudioUnitSubType_VoiceProcessingIO
//    desc.componentFlags = 0
//    desc.componentFlagsMask = 0
//    desc.componentManufacturer = kAudioUnitManufacturer_Apple
//
//    let inputComponent: AudioComponent = AudioComponentFindNext(nil, &desc)
//
//    status = AudioComponentInstanceNew(inputComponent, &audioUnit)
//    checkStatus(status)
//
//    var flag = UInt32(1)
//    status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flag, UInt32(sizeof(UInt32)))
//    checkStatus(status)
//
//    status = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputBus, &flag, UInt32(sizeof(UInt32)))
//    checkStatus(status)
//
//    var audioFormat: AudioStreamBasicDescription! = AudioStreamBasicDescription()
//    audioFormat.mSampleRate = 8000
//    audioFormat.mFormatID = kAudioFormatLinearPCM
//    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
//    audioFormat.mFramesPerPacket = 1
//    audioFormat.mChannelsPerFrame = 1
//    audioFormat.mBitsPerChannel = 16
//    audioFormat.mBytesPerPacket = 2
//    audioFormat.mBytesPerFrame = 2
//
//    status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &audioFormat, UInt32(sizeof(UInt32)))
//    checkStatus(status)
//
//
//    try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
//    status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &audioFormat, UInt32(sizeof(UInt32)))
//    checkStatus(status)
//
//
//    // Set input/recording callback
//    var inputCallbackStruct = AURenderCallbackStruct(inputProc: recordingCallback, inputProcRefCon: UnsafeMutablePointer(unsafeAddressOf(self)))
//    AudioUnitSetProperty(audioUnit, AudioUnitPropertyID(kAudioOutputUnitProperty_SetInputCallback), AudioUnitScope(kAudioUnitScope_Global), 1, &inputCallbackStruct, UInt32(sizeof(AURenderCallbackStruct)))
//
//
//    // Set output/renderar/playback callback
//    var renderCallbackStruct = AURenderCallbackStruct(inputProc: playbackCallback, inputProcRefCon: UnsafeMutablePointer(unsafeAddressOf(self)))
//    AudioUnitSetProperty(audioUnit, AudioUnitPropertyID(kAudioUnitProperty_SetRenderCallback), AudioUnitScope(kAudioUnitScope_Global), 0, &renderCallbackStruct, UInt32(sizeof(AURenderCallbackStruct)))
//
//
//    flag = 0
//    status = AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, kInputBus, &flag, UInt32(sizeof(UInt32)))
//}
