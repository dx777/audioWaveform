//
//  ScrollableWaveformView.swift
//  WaveForm
//
//  Created by David Kyslenko on 31.10.2022.
//

import Foundation
import UIKit
import SnapKit
import AVFoundation

struct MagnetOptions {
    var magnetWhileScrolling: Bool = true
    var distanceToMagnet: CGFloat = 30
}

class ScrollableWaveformView: UIView {
    private var lastOffset: CGPoint = .zero
    private var lastOffsetCapture: TimeInterval = .zero
    private var isScrollingFast: Bool = false
        
    private var isTouched: Bool = false
    private var magnetConfig: MagnetOptions = MagnetOptions()
    private var curentMagnetIndex: Int = 0
    private var offsetPercent: CGFloat = 0
    private var scrollSpeed: Float = 0
    
    var cursorWidth: CGFloat {
        return 2
    }
    
    var cursorMaxOffsetX: CGFloat {
        return UIScreen.main.bounds.width / 2.0
    }
    
    var cursorOffsetX: CGFloat {
        return  cursorMaxOffsetX
    }
    
    var cursorColor: UIColor {
        return UIColor(hex: "BDF061")
    }
    
    var waveformWidth: CGFloat {
        return CGFloat(soundData.count) * CGFloat((waveSegmentWidth + waveSpacingBetweenSegments)) * scaleX
    }
    
    var snapPointRegularColor: UIColor {
        return .white
    }
    
    var snapPointFocusedColor: UIColor {
        return UIColor(hex: "F09E56")
    }
    
    var snapPointFocusedSize: CGFloat {
        return 8
    }
    
    var snapPointSize: CGFloat {
        return 8
    }
    
    var scrollViewHeight: CGFloat = 100
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = waveSpacingBetweenSegments
        return stackView
    }()
    
    private lazy var cursorView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = cursorColor
        contentView.tag = 1
        return contentView
    }()
    
    private lazy var bgView: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor(hex: "25272E")
        return lineView
    }()
    
    
    private var soundData: [Float] = []
    
    private var currentIndex: Int = 0
    private var waveSegmentWidth: CGFloat = 2
    private var waveSpacingBetweenSegments: CGFloat = 1
    private var waveBackgroundColor: UIColor = UIColor(hex: "7A9EF0")
    private var barTintColor: UIColor = .blue
        
    var minimumScaleX: CGFloat = 0.3
    var maximumScaleX: CGFloat = 3
    
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    
    var snapPoints: [CGFloat] = []//in Percent
    var snapViews: [UIView] = []
    var path: UIBezierPath!
    
    var pathPoints: [CGPoint] = []
    var smoothCorners: Bool = false

    init() {
        super.init(frame: .zero)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        let contentWidth: CGFloat = CGFloat(soundData.count) * CGFloat((waveSegmentWidth + waveSpacingBetweenSegments)) * scaleX
        
        let stackWaveH = (scrollViewHeight - 30)
        path = UIBezierPath.curvedPaths(points: pathPoints, in: CGRect(x: 0, y: 0, width: contentWidth, height: stackWaveH * scaleY))
        
        guard !smoothCorners else { return }
        
        let maskForYourPath = CAShapeLayer()
        maskForYourPath.path = path.cgPath
        
        stackView.layer.mask = maskForYourPath
        
        smoothCorners = true
    }
    
    func setUI() {
        scrollView.isUserInteractionEnabled = true
        stackView.isUserInteractionEnabled = false
        bgView.isUserInteractionEnabled = false
        
        let gestureRecognizers = scrollView.gestureRecognizers ?? []
        
        for gesture in gestureRecognizers {
            if gesture.isKind(of: UIPinchGestureRecognizer.self) {
                gesture.isEnabled = false
            }
        }
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        scrollView.addGestureRecognizer(pinchGesture)
        addSubview(scrollView)
        
        scrollView.addSubview(bgView)
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalToSuperview().offset(cursorMaxOffsetX)
            
            make.height.equalToSuperview().multipliedBy((scrollViewHeight-30)/scrollViewHeight)
            make.bottom.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(4)
        }
        
        bgView.snp.makeConstraints { make in
            make.left.equalTo(stackView.snp.left)
            make.top.equalTo(stackView.snp.top).offset(4)
            make.height.equalTo(stackView.snp.height)
            make.right.equalTo(stackView.snp.right)
        }
        
        scrollView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(scrollViewHeight)
        }
        
        addSubview(cursorView)
        cursorView.layer.cornerRadius = 1
        cursorView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(cursorMaxOffsetX - cursorWidth/2)
            make.top.equalTo(scrollView.snp.top).offset(4)
            make.bottom.equalTo(bgView.snp.bottom).offset(4)
            make.width.equalTo(cursorWidth)
        }
    }
    
    func drawWaveformView(values: [Float], magnetPoints: [CGFloat] = [0.0, 0.1,0.15,0.2,0.3,0.4,0.5,0.6,0.7,0.75,0.8,0.9]) {
        self.soundData = values
        
        let max = values.max() ?? 1
        let waveStackH: CGFloat = scrollViewHeight - 30
        
        for i in 0 ..< values.count {
            let value = values[i]
            let view = UIView()
            
            let subView = UIView()
            view.addSubview(subView)
            subView.backgroundColor = waveBackgroundColor
            let barHight = (Float(waveStackH) * value/max)/2
            subView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(waveStackH)
            }
            
            stackView.addArrangedSubview(view)
            view.snp.makeConstraints { make in
                make.height.equalToSuperview()
                make.width.equalTo(waveSegmentWidth * scaleX)
            }
            
            
            let waveformMiddleY: CGFloat = 10 + waveStackH/2
            let pointOffset = waveformMiddleY - CGFloat(barHight)
            let point = CGPoint(x: CGFloat(i) * waveSegmentWidth + CGFloat(i - 1) * waveSpacingBetweenSegments, y: CGFloat(pointOffset))
            pathPoints.append(point)
            
            debugPrint("path point \(point)")
        }
        
        let waveStackMaxY: CGFloat = waveStackH + 10
        //
        var mirorPoints: [CGPoint] = []
        for i in 0 ..< pathPoints.count {
            let point = pathPoints[pathPoints.count - 1 - i]
            let mirorPoint = CGPoint(x: point.x, y: waveStackMaxY - point.y)
            mirorPoints.append(mirorPoint)
        }
        
        
        pathPoints.append(contentsOf: mirorPoints)
        

        drawSnapPoints(with: magnetPoints)
        calculateMinScale()
        //update scrollView contentSize
        let newSpacing = waveSpacingBetweenSegments * scaleX
        let newBarWdith = waveSegmentWidth * scaleX
        let newContentWidth: CGFloat =  CGFloat(soundData.count) * CGFloat((newBarWdith + newSpacing))
        
        let extraContent: CGFloat = UIScreen.main.bounds.width // haft and begin and hafl and the end
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) { [weak self] in
            guard let `self` = self else { return }
            self.scrollView.contentSize = CGSize(width: newContentWidth + extraContent, height: self.scrollViewHeight)
        }
        setNeedsDisplay()
    }
    
    func drawSnapPoints(with values: [CGFloat]) {
        snapPoints = values
        snapViews.forEach({$0.removeFromSuperview()})
        
        var minDistance = CGFloat.greatestFiniteMagnitude
        for i in 0 ..< snapPoints.count {
            let percent = snapPoints[i]
            let pView = UIView()
            pView.backgroundColor = snapPointRegularColor
            pView.layer.cornerRadius = snapPointSize/2.0
            scrollView.addSubview(pView)
            let offset: CGFloat = waveformWidth * CGFloat(percent) - snapPointSize/2.0
            pView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-3)
                make.width.height.equalTo(snapPointSize)
                make.left.equalToSuperview().offset(cursorMaxOffsetX + offset)
            }
            
            snapViews.append(pView)
            
            //find min distance
            let nextIndex = i + 1
            if nextIndex < snapPoints.count - 1 {
                let nextOffset = waveformWidth * CGFloat(snapPoints[nextIndex])
                let distance = nextOffset -  offset
                if abs(distance) < minDistance {
                    minDistance = distance
                }
            }
        }
        
        magnetConfig.distanceToMagnet = max(10,  min(30,  minDistance/2 - 5))
        debugPrint("calculate distance \(minDistance). -> \(magnetConfig.distanceToMagnet)")
        
        hightLightMagnetPoint()
    }
    
    func resetWaveView() {
        currentIndex = 0
        scrollView.setContentOffset(.zero, animated: false)
        resetStackWave()
        cursorView.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(cursorMaxOffsetX - cursorWidth/2)
        }
        calculateMinScale()
    }
    
    
    func resetStackWave() {
        let barViews = stackView.arrangedSubviews
        
        for i in 0 ..< barViews.count {
            let col = barViews[i]
            
            if let x = col.subviews.first {
                x.backgroundColor = waveBackgroundColor
            }
        }
    }
    
    
    func calculateMinScale() {
        let contentWidth: CGFloat = CGFloat(soundData.count) * CGFloat((waveSegmentWidth + waveSpacingBetweenSegments))
        let minScale = UIScreen.main.bounds.width / contentWidth
        self.minimumScaleX = minScale
    }
    
    func hightLightMagnetPoint() {
        for i in 0 ..< snapViews.count {
            snapViews[i].backgroundColor = i == curentMagnetIndex ? snapPointFocusedColor : snapPointRegularColor
            let scale = i == curentMagnetIndex ? 1.2 : 1
            snapViews[i].transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        }
    }
    
    func calculateDistanceToMagnet(at offset: CGFloat) -> CGFloat {
        
        var rightIndex: Int = snapPoints.count - 1
        for i in 0 ..< snapPoints.count {
            let point = snapPoints[i]
            
            let pointOffset = waveformWidth * point + snapPointSize/2.0
            
            if pointOffset >= offset {
                rightIndex = i
                break
            }
        }
        let leftIndex = min(0, rightIndex - 1)
        
        let distance = (snapPoints[rightIndex]  - snapPoints[leftIndex]) * waveformWidth
        
        return max(10, min(30, distance/2 - 5))
    }
    
    deinit {
        print(self, "Deinited")
    }
}

extension ScrollableWaveformView {
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        let prevScale = scaleX
        scaleX = scaleX *  gesture.scale
        
        scaleX = max(minimumScaleX, scaleX)
        scaleX = min(maximumScaleX, scaleX)
        debugPrint("handlePinchGesture ->\(gesture.scale) -> \(scaleX)")
        
        let newSpacing = waveSpacingBetweenSegments * scaleX
        let newBarWdith = waveSegmentWidth * scaleX
        let contentWidth: CGFloat = CGFloat(soundData.count) * CGFloat((waveSegmentWidth + waveSpacingBetweenSegments))
        let newContentWidth: CGFloat =  CGFloat(soundData.count) * CGFloat((newBarWdith + newSpacing))
        
        let extraContent: CGFloat = UIScreen.main.bounds.width
        
        scrollView.contentSize = CGSize(width: newContentWidth + extraContent, height: scrollViewHeight)
        
        let diffSizeAfterZoom = (newContentWidth - contentWidth)/2
        
        stackView.transform = CGAffineTransform.identity.translatedBy(x: diffSizeAfterZoom, y: 0).scaledBy(x: scaleX, y: 1)
        bgView.transform = CGAffineTransform.identity.translatedBy(x: diffSizeAfterZoom, y: 0).scaledBy(x: scaleX, y: 1)
        
        // recenter cursorView
        
        let totalBarWidth = (waveSegmentWidth * prevScale + waveSpacingBetweenSegments * prevScale)
        let index = scrollView.contentOffset.x / totalBarWidth
        
        let offset = CGFloat(index) * (newSpacing + newBarWdith)

        if Int(index) < soundData.count {
            debugPrint("xxxx \(scrollView.contentOffset.x) -> \(contentWidth) -> \(newContentWidth)")
        }
        
        if offset >= 0 {
            debugPrint("scrollView offsetX \(index)  -> \(prevScale) ->\(scaleX)")
            
            scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        } else {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
        
        
        //update magnetView position
        for i in 0 ..< min(snapPoints.count, snapViews.count) {
            let percent = snapPoints[i]
            let pView = snapViews[i]
            let offset: CGFloat = newContentWidth * CGFloat(percent) - snapPointSize/2
            pView.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(cursorOffsetX + offset)
            }
        }
        gesture.scale = 1.0
        
        debugPrint("contentWidth \(contentWidth)")
    }
    
}

extension ScrollableWaveformView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleMagnetWhenStopScroll()
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        debugPrint("scrollView BeginDragging \(scrollView.contentOffset.x)")
        isTouched = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        debugPrint("scrollView DidEndDragging \(scrollView.contentOffset.x)")
        
        guard isTouched else { return }
        isTouched = false
        guard !decelerate else { return }
        handleMagnetWhenStopScroll()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {        
        guard self.isTouched else { return }
        let contentOffset = scrollView.contentOffset//.x + UIScreen.main.bounds.width
        
        let currentTime = Date.timeIntervalSinceReferenceDate
        let timeDiff = currentTime - lastOffsetCapture
        let captureInterval = 0.3
        
        if timeDiff > captureInterval, magnetConfig.magnetWhileScrolling {
            
            let distance = contentOffset.x - lastOffset.x     // calc distance
            let scrollSpeedNotAbs = (distance * 10) / 1000     // pixels per ms*10
            scrollSpeed = fabsf(Float(scrollSpeedNotAbs)) * 2 // absolute value
            print("scrollSpeed", scrollSpeed)
            
            if scrollSpeed > 0.05 {
                isScrollingFast = true
                print("Fast")
            } else {
                isScrollingFast = false
                print("Slow")
                for i in 0 ..< snapPoints.count {
                    let point = snapPoints[i]
                    let pointOffset = cursorMaxOffsetX + waveformWidth * point +  snapPointSize/2.0
                    let distanceToPoint = pointOffset - (contentOffset.x + cursorOffsetX + cursorWidth/2)
                    
                    let distanceToMagnet = min(30, magnetConfig.distanceToMagnet * scaleX)
                    if abs(distanceToPoint) <  distanceToMagnet{
                        //
                        debugPrint("should magnet \(distance >= 0 ? "leftRoRight" : "rightToLeft")")
                        
                        let shouldMagnet = distance * distanceToPoint > 0
                        if shouldMagnet {
                            break
                        }
                        
                    }
                }
            }
            
            lastOffset = contentOffset
            lastOffsetCapture = currentTime
        }
    }
    
    func handleMagnetWhenStopScroll() {
        guard scrollSpeed > 0.07 else { return }
        print(#function)
        
        let contentOffset = scrollView.contentOffset
        let lastRightPoint = snapPoints[snapPoints.count - 1] * waveformWidth + snapPointSize/2.0
        
        if contentOffset.x <= 0 {
            scrollToPoint(at: 0)
        }  else {
            var leftIndex: Int = 0
            var rightIndex: Int = 1
            
            for i in 0 ..< snapPoints.count - 1 {
                let leftPoint = snapPoints[i] * waveformWidth  + snapPointSize/2.0
                let rightPoint = snapPoints[i+1] * waveformWidth  + snapPointSize/2.0
                if leftPoint <= contentOffset.x && rightPoint >= contentOffset.x {
                    leftIndex = i
                    rightIndex = i + 1
                    break
                }
            }
            
            var leftPoint = snapPoints[leftIndex] * waveformWidth
            var rightPoint = snapPoints[rightIndex] * waveformWidth
            
            //if content offset is the right of last magnet point
            if contentOffset.x > lastRightPoint {
                leftIndex = snapPoints.count - 1
                leftPoint = lastRightPoint
                rightPoint = lastRightPoint + 1000
            }
            
            let distance = (rightPoint  - leftPoint)
            
            let distanceToMagnet: Float  = Float(max(10, min(30, distance/2 - 3)))
            
            let distanceToLeft = fabsf(Float(leftPoint - contentOffset.x))
            let distanceToRight = fabsf(Float(rightPoint - contentOffset.x))
            if distanceToLeft < distanceToRight && distanceToLeft <= distanceToMagnet{
                
                scrollToPoint(at: leftIndex)
            } else if distanceToRight <= distanceToMagnet {
                scrollToPoint(at: rightIndex)
            } else {
                debugPrint("distanceToMagnet__ \(distanceToMagnet) -> \(distanceToLeft) -> \(distanceToRight)")
                
            }
            debugPrint("distanceToMagnet \(distanceToMagnet)")
            
        }
        
        func scrollToPoint(at index: Int) {
            let point: CGFloat = snapPoints[index]
            let delta: CGFloat =  0 //self.magnetViewSize/2
            let distance = fabsf(Float(waveformWidth * point +  delta - contentOffset.x))
            let scrollTimer = Float(distance) / scrollSpeed
            curentMagnetIndex = index
            
            UIView.animate(withDuration: TimeInterval(scrollTimer)) {
                self.scrollView.setContentOffset(CGPoint(x: self.waveformWidth * point +  delta , y: 0), animated: true)
            }completion: { _ in
                UIView.animate(withDuration: 0.25) {
                    self.hightLightMagnetPoint()
                }
            }
        }
    }
}
