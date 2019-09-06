//
//  SceneDetector.swift
//  ScenePlayer
//
//  Created by Chiharu Nameki on 2019/09/05.
//  Copyright © 2019 Chiharu Nameki. All rights reserved.
//

import Foundation
import AVFoundation

class SceneDetector: NSObject {
    private var completion: (([CMTime])->())?
    private var sceneStartTimes: [CMTime] = [.zero]
    
    private var player: AVPlayer?
    private var stepCount: Int = 1
    private var stepInterval: TimeInterval = 0.2
    private var previousColor: [Int] = [0, 0, 0]
    
    deinit {
        player?.currentItem?.outputs.compactMap({ $0 as? AVPlayerItemVideoOutput}).forEach({
            $0.setDelegate(nil, queue: nil)
        })
        completion?([])
    }
    
    func start(url: URL, completion: @escaping ([CMTime])->()) {
        let item = AVPlayerItem(url: url)
        guard let videoTrack = item.asset.tracks.first(where: { $0.mediaType == .video }) else {
            completion([])
            return
        }
        
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes:
            [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32ARGB,
             kCVPixelBufferWidthKey as String : 1,
             kCVPixelBufferHeightKey as String : 1]
        )
        output.setDelegate(self, queue: DispatchQueue.global())
        item.add(output)
        
        self.completion = completion
        self.player = AVPlayer(playerItem: item)
        
        // chache these values in order to reduce calculation in loop
        let interval: TimeInterval = 0.2
        self.stepCount = Int(interval / videoTrack.minFrameDuration.seconds)
        self.stepInterval = Double(stepCount) * videoTrack.minFrameDuration.seconds
    }
}

extension SceneDetector: AVPlayerItemOutputPullDelegate {
    func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) {
        guard let player = player else { return }
        
        let currentTime = player.currentTime()
        var displayTime: CMTime = .zero
        guard let buffer = (output as? AVPlayerItemVideoOutput)?
            .copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: &displayTime) else { return }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        if let data = CVPixelBufferGetBaseAddress(buffer) {
            
            let r = Int((data + 1).load(as: UInt8.self))
            let g = Int((data + 2).load(as: UInt8.self))
            let b = Int((data + 3).load(as: UInt8.self))
            
            let pre = previousColor
            let d = sqrt(Double((pre[0] - r) * (pre[0] - r) + (pre[1] - g) * (pre[1] - g) + (pre[2] - b) * (pre[2] - b))) / 255
            
            previousColor[0] = r
            previousColor[1] = g
            previousColor[2] = b
            
            if let start = sceneStartTimes.last?.seconds, 2.5 < displayTime.seconds - start, 0.1 < d {
                sceneStartTimes.append(displayTime)
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        let next = displayTime.seconds + stepInterval
        if let duration = player.currentItem?.duration, (next < duration.seconds || duration == .indefinite) {
             player.currentItem?.step(byCount: stepCount)
        } else {
            completion?(sceneStartTimes)
            completion = nil
        }
    }
}
