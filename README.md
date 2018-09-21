---
title: 跑步过程中播报跑步数据，实现长时间后台保活
date: 2017-11-28 18:10:18
tags:
---

编写跑步app的时候音频播放总是面临着三个问题：

1. 如何保证app长时间后台运行
2. 如何在播报语音(几十个mp3文件)时保障连贯性
3. 利用AudioSession如何处理好与其他同类型app播放的冲突

当时经过对竞品app的研究发现，实现长时间后台运行采用其中一种方式：持续播放无声音乐
对于第二个问题，我们一直在试错：

* 第一种方式将即将播放的语音文件名存入数组中，轮询播放数组里文件
* 第二种方式将即将播放的语音提前初始化AudioPlayer缓存到内存中，轮询播放

（这两种方式呢都没有保障播放的连贯性，而且如果用户手机里安装了同样采用此种做法的app的话，AudioSession设置比较复杂，而且播放中出现‘抢夺播放’导致播放卡顿的问题肯定会存在。）
<!--more-->

* 第三种方式利用AVMutableComposition合并所有即将播放的文件成一个文件，单独播放这一个文件既解决连贯性也解决了抢夺播放的问题

### 程序保活
AudioSession的设置：

 * 播放无音音乐实现程序后台持续运行，category: AVAudioSessionCategoryPlayback。
 * 需要考虑不要影响其他app的音频播放，比如音乐类软件, options: . mixWithOthers(混响)
**调用AudioPlayer播放前先设置AudioSession**

``` swift
do {
    try self.audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
    try self.audioSession.setActive(true)
} catch let error {
    debugPrint("\(type(of:self)):\(error)")
}
```
#### 1. 场景
``` swift	
// 背景音乐
enum AudioPlayScene {
	case normal     // 前台播放，后台不播放，为了用户在使用时可以任意修改音量
	case none       // 前后台都不播放
	case run        // 前后台都需要播放，用于跑步过程中
}
```

根据自己的需求设置 **AudioManager.shared.audioPlayScene**

#### 2. 启动保活

实现保活需要在**AppDelegate**中实现必要的两个回调函数

``` swift
func applicationDidEnterBackground(_ application: UIApplication) 
{
	// 不在跑步页面才需要关闭
   if AudioManager.shared.audioPlayScene != .run 
   	{
   		AudioManager.shared.openBackgroundAudioAutoPlay = false
   	}
}
func applicationDidBecomeActive(_ application: UIApplication) 
{
	AudioManager.shared.openBackgroundAudioAutoPlay = true
}
```

### 播报
AudioModel 对数据的处理和封装
MergeAudioTool 对AudioModel的数据进行合并

``` swift
func play() {
   	var audioText = [[String: [String]]]()
   	audioText.append(["altitude": ["3","2","1","relax","3","2","1","relax"]])
    guard let audioModel = AudioModel(res: audioText) else{return}
    AudioManager.shared.playWithModel(res: audioModel)
}
```

[Demo](https://gitee.com/pengkun/AudioPlayer)