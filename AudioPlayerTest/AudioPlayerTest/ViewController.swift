//
//  ViewController.swift
//  AudioPlayerTest
//
//  Created by pk on 2017/10/11.
//  Copyright © 2017年 pk. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 后台保活
        AudioManager.shared.audioPlayScene = .run
        
        let timer = Timer(timeInterval: 15.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
        timer.fireDate = Date(timeIntervalSinceNow: 20)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func timerUpdate() {
        var audioText = [[String: [String]]]()
        audioText.append(["altitude": ["3","2","1","relax","3","2","1","relax"]])
        guard let audioModel = AudioModel(res: audioText) else{return}
        AudioManager.shared.playWithModel(res: audioModel)
    }
}

