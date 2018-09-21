//
//  AudioConfig.swift
//  AudioPlayerTest
//
//  Created by pk on 2017/3/15.
//  Copyright © 2017年 pk. All rights reserved.
//

import Foundation

enum VoiceType: Int32 {
    case male    = 0
    case female  = 1
}
class AudioConfig {
    static let shared = AudioConfig()
    // 播报开关
    var isVoiceOn = true
    // 默认男声
    var voiceType = VoiceType.male

    init() {

    }
}
