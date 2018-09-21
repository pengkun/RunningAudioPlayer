//
//  AudioModel.swift
//  AudioPlayerTest
//
//  Created by pk on 2017/3/15.
//  Copyright © 2017年 pk. All rights reserved.
//

import Foundation
import AVFoundation

class AudioModel {

    var audioResArr: [String] = []

    init() {}

    init?(res: [[String: [String]]]) {
        if !self.updateResource(res) {
            return nil
        }
    }

    init?(res: String) {
        if !self.updateResource([[res : []]]) {
            return nil
        }
    }

    private func updateResource(_ res: [[String: [String]]]) ->  Bool {
        if AudioConfig.shared.isVoiceOn {

            for rArr in res {
                for (rKey, rValue) in rArr {
                    guard let fullName = self.voiceFullName(rKey) else {return false}
                    self.audioResArr.append(fullName)
                    for name in rValue {
                        guard let fullName = self.voiceFullName(name) else{return false}
                        self.audioResArr.append(fullName)
                    }
                }
            }
        }
        return true
    }

    /// 获取音频的完整路径
    ///
    /// - Parameter name: 音频名
    /// - Returns: a path. `nil` on error.
    func voiceFullName(_ name: String) -> String? {
        let fullName = "\(AudioConfig.shared.voiceType.rawValue)"+"_"+name+".mp3"

        let path = Bundle.main.path(forResource: fullName, ofType: nil)
        guard path != nil  else {
            debugPrint("error: voice path is nil.. voiceanme = \(name)")
            return nil
        }
        return path
    }

    func createPlayer(_ name: String) -> AVAudioPlayer? {
        let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: name, ofType: nil)!))
        return player
    }
}
