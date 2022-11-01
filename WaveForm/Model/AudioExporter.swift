//
//  AudioExporter.swift
//  VIWavefromView
//
//  Created by Vito on 28/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation


public class AudioExporter {
    public var resultPoints = [Float]()
    
    private var audioSamples = [VIAudioSample]()
        
    private let itemsPerPointCount = 44
    public var operationQueue: DispatchQueue?
    
    public var minWidthPerSecond: CGFloat = 1
    public var minWidthToGenerate: CGFloat = 500
    
    fileprivate(set) var actualWidthPerSecond: CGFloat = 0
}

public extension AudioExporter {
    func load(from asset: AVAsset, completion: @escaping ((Error?) -> Void)) -> Cancellable {
        let cancellable = Cancellable()
        
        asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"], completionHandler: { [weak self] in
            guard let strongSelf = self else { return }
            
            var error: NSError?
            let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &error)
            if tracksStatus != .loaded {
                completion(error)
                return
            }
            let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
            if durationStatus != .loaded {
                completion(error)
                return
            }
            
            let duration = asset.duration.seconds
            
            strongSelf.actualWidthPerSecond = strongSelf.minWidthToGenerate / CGFloat(duration)
            print("actualWidthPerSecond", strongSelf.actualWidthPerSecond)
            
            let operation = VIAudioSampleOperation(widthPerSecond: strongSelf.actualWidthPerSecond)
            if let queue = strongSelf.operationQueue {
                operation.operationQueue = queue
            }
            
            func updatePoints(with audioSamples: [VIAudioSample]) {
                var points: [Float] = []
                if let audioSample = audioSamples.first {
                    points = audioSample.samples.map({ (sample) -> Float in
                        return Float(sample / 12000.0)
                    })
                }
                strongSelf.resultPoints = points
            }
            
            let operationTask = operation.loadSamples(from: asset, progress: { [weak self] (audioSamples) in
                self?.audioSamples = audioSamples
                updatePoints(with: audioSamples)
                
            }, completion: { (audioSamples, error) in
                guard let audioSamples = audioSamples else {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                    return
                }
                updatePoints(with: audioSamples)
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            })
            cancellable.cancelBlock = {
                operationTask?.cancel()
            }
        })
        cancellable.cancelBlock = {
            asset.cancelLoading()
        }
        return cancellable
    }
}
