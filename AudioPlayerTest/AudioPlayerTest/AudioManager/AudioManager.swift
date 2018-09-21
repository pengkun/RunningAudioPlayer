//
//  AudioManager.swift
//  AudioPlayerTest
//
//  Created by pk on 2017/3/15.
//  Copyright © 2017年 pk. All rights reserved.
//

import Foundation
import AVFoundation
import CoreTelephony

// 背景音乐
enum AudioPlayScene {
    case normal     // 前台需要播放，后台不需要播放
    case none       // 前后台都不播放
    case run        // 前后台都需要播放
}


class AudioManager: NSObject {
    
    static let shared = AudioManager()
    fileprivate let audioSession = AVAudioSession.sharedInstance()
    fileprivate var backgroundAudioPlayer: AVAudioPlayer?
    fileprivate var resAudioPlayer: AVAudioPlayer?
    fileprivate var audioModel = AudioModel()
    
    // 是否开启后台播放无声音乐
    var audioPlayScene: AudioPlayScene = .normal
    var openBackgroundAudioAutoPlay = false {
        didSet { self.didSetOpenBackgroundAudioAutoPlay() }
    }
    
    // 判断是否有电话进入。跑步过程中关闭语音文件的播放
    let callCenter = CTCallCenter()
    
    // 判断是否有中断。跑步过程中关闭语音文件的播放
    var isInterruption: Bool = false {
        didSet {
            if isInterruption == true {
                self.audioModel.audioResArr.removeAll()
                self.stopResPlayer()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init() {
        super.init()
        self.setupListener()
    }
}

// MARK: - 背景音乐相关
extension AudioManager {
    fileprivate func setupBGAudioSession() {
        do {
            try self.audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try self.audioSession.setActive(true)
        } catch let error {
            debugPrint("\(type(of:self)):\(error)")
        }
    }
    
    fileprivate func setupBackgroundAudioPlayer() {
        guard self.backgroundAudioPlayer == nil else { return }
        do {
            self.backgroundAudioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "blank", ofType: "mp3")!))
        } catch let error {
            debugPrint("\(type(of:self)):\(error)")
        }
        self.backgroundAudioPlayer?.numberOfLoops = -1
        self.backgroundAudioPlayer?.volume = 1.0
    }
    
    fileprivate func setupListener() {
        // 监听接打电话电话
        self.callCenter.callEventHandler = {[weak self] call in
            
            if (call.callState == CTCallStateDisconnected) {
                print("已挂断=\(call.callID)")
                self?.isInterruption = false
            }
            else if (call.callState == CTCallStateConnected) {
                print("通话中=\(call.callID)")
                self?.isInterruption = true
            }
            else if (call.callState == CTCallStateIncoming) {
                print("被叫中=\(call.callID)")
                self?.isInterruption = true
            }
            else if (call.callState == CTCallStateDialing) {
                print("发起主叫=\(call.callID)")
                self?.isInterruption = true
            }
        }
    }
    
    fileprivate func playBackGroundAudio() {
        guard self.openBackgroundAudioAutoPlay else {return}
        self.setupBGAudioSession()
        self.setupBackgroundAudioPlayer()
        
        self.backgroundAudioPlayer?.prepareToPlay()
        self.backgroundAudioPlayer?.play()
    }
    
    fileprivate func stopBackGroundPlayer() {
        if let player = self.backgroundAudioPlayer {
            player.delegate = nil
            player.stop()
            self.backgroundAudioPlayer = nil
            try? self.audioSession.setActive(false)
        }
    }
}

// MARK: - 控制开关背景音乐
extension AudioManager {
    fileprivate func didSetOpenBackgroundAudioAutoPlay() {
        if self.openBackgroundAudioAutoPlay {
            // 判断是否开启后台播放无声音乐(排除欢迎页面，欢迎页面有音乐)
            if self.audioPlayScene == .normal || self.audioPlayScene == .run {
                guard self.resAudioPlayer == nil else { return }
                guard self.resAudioPlayer?.isPlaying == false || self.resAudioPlayer?.isPlaying == nil else { return }
                guard self.backgroundAudioPlayer?.isPlaying == false || self.backgroundAudioPlayer?.isPlaying == nil else { return }
                
                self.playBackGroundAudio()
            } else {
                self.openBackgroundAudioAutoPlay = false
            }
        } else {
            if self.audioPlayScene != .run {
                self.stopBackGroundPlayer()
            }
        }
    }
}

// MARK: - 播放音乐资源文件
extension AudioManager {
    private func setupResAudioSession() {
        do {
            try self.audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
            try self.audioSession.setActive(true)
        } catch let error {
            debugPrint("\(type(of:self)):\(error)")
        }
    }
    
    private func playResPlayer(reses: [String]) {
        guard self.isInterruption == false else { return }
        self.stopBackGroundPlayer()
        self.stopResPlayer()
        
        MergeAudio.mergeAudio(audioPath: reses, completed: { (path) in
            self.setupResAudioSession()
            if let truePath = path {
                do {
                    self.resAudioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: truePath))
                } catch let error {
                    debugPrint("\(type(of:self)):\(error)")
                }
                self.resAudioPlayer?.volume = 1
                self.resAudioPlayer?.delegate = self
                self.resAudioPlayer?.prepareToPlay()
                self.resAudioPlayer?.play()
            }
        })
        
    }
    
    func stopResPlayer() {
        if let player = self.resAudioPlayer {
            player.delegate = nil
            player.stop()
            self.resAudioPlayer = nil
        }
    }
    
    //刷新播报
    fileprivate func updatePlay() {
        guard (self.resAudioPlayer == nil) else {return}
        if self.audioModel.audioResArr.count > 0 {
            self.playResPlayer(reses: self.audioModel.audioResArr)
            self.audioModel.audioResArr.removeAll()
        }
    }
    
    func playWithModel(res: AudioModel) {
        guard self.isInterruption == false else { return }
        guard res.audioResArr.count > 0 else { return }
    
        self.audioModel = res
        self.updatePlay()
    }
}

// MARK: - 扩展 播放代理
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == self.resAudioPlayer {
            if self.audioModel.audioResArr.count == 0{
                try? self.audioSession.setActive(false, with: .notifyOthersOnDeactivation)
                self.stopResPlayer()
                self.openBackgroundAudioAutoPlay = true
            }else {
                self.stopResPlayer()
                self.updatePlay()
            }
        }
    }
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        debugPrint("\(type(of:self))" + error.debugDescription)
    }
}

