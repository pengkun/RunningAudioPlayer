//
//  MergeAudioTool.swift
//  AudioPlayerTest
//
//  Created by pk on 2017/10/12.
//  Copyright © 2017年 pk. All rights reserved.
//

import Foundation
import AVFoundation

class MergeAudio {
    
    static func mergeAudio(audioPath: [String], completed:@escaping (_ path: String?) -> Void) {
        guard audioPath.count > 1 else {
            completed(audioPath.first)
            return
        }
        //  合并所有的录音文件
        let composition = AVMutableComposition()
        //  音频插入的开始时间
        var beginTime = kCMTimeZero
        //  获取音频合并音轨
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var assets: [AVURLAsset] = []
        audioPath.forEach {
            debugPrint("name = \($0) \n")
            
            let audioAsset = AVURLAsset(url: URL(fileURLWithPath: $0))
            assets.append(audioAsset)
            
            let audioTimeRange = CMTimeRange(start: kCMTimeZero, duration: audioAsset.duration)
            
            do {
                try audioTrack.insertTimeRange(audioTimeRange, of: audioAsset.tracks(withMediaType: AVMediaTypeAudio)[0], at: beginTime)
            }
            catch let error {
                debugPrint("插入失败\(error)")
            }
            
            beginTime = CMTimeAdd(beginTime, audioAsset.duration)
        }
        
        let docPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).last!
        let filePath: String = docPath.appending("/Caches/MergeAudio")
        let contentPath: String = filePath.appending("/dest.m4a")
        //  如果目标文件已经存在删除目标文件
        if FileManager.default.fileExists(atPath: contentPath) {
            do {
                try FileManager.default.removeItem(atPath: contentPath)
            } catch let error {
                debugPrint("删除文件失败:\(error)")
            }
        }
        else {
            do {
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                debugPrint("error = \(error.localizedDescription)")
            }
        }
        
        let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        session?.outputURL = URL(fileURLWithPath: contentPath)
        session?.outputFileType = AVFileTypeAppleM4A
        //        session?.shouldOptimizeForNetworkUse = true
        session?.exportAsynchronously(completionHandler: {
            if session?.status == .completed {
                debugPrint("合成成功 \(contentPath)")
                DispatchQueue.main.async {
                    completed(contentPath)
                }
            }
            else {
                debugPrint("合成失败 \(session?.error)")
            }
        })
    }
}
