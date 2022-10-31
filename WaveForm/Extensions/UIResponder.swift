//
//  UIResponder.swift
//  WaveForm
//
//  Created by David Kyslenko on 31.10.2022.
//

import UIKit

let mockupScreenHeight: CGFloat = 812
let mockupScreenWidth: CGFloat = 375

extension UIResponder {
    func calculateHeightMultiplier(_ height: CGFloat) -> CGFloat {
        let multiplier = height / mockupScreenHeight
        let screenHeight = UIScreen.main.bounds.height
        return screenHeight * multiplier
    }
    
    func calculateWidthMultiplier(_ width: CGFloat) -> CGFloat {
        let multiplier = width / mockupScreenWidth
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth * multiplier
    }
}
