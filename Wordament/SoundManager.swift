//
//  SoundManager.swift
//  Wordament
//
//  Created by saif ahmed on 09/09/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit
class SoundManager {
    
    static func playVibration() {
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    static func playImpactFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    static func playSoundForRightWord() {
        guard  let rightWordSound =  Bundle.main.path(forResource: "right_tone", ofType: "mp3") else {
            print("can not find sound")
            return
        }
        do {
        let soundURL = URL(fileURLWithPath: rightWordSound)
        let player = try AVAudioPlayer(contentsOf: soundURL)
            player.volume = 1.0 
            player.prepareToPlay()
            player.play()
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
}
