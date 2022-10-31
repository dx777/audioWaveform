//
//  PathCommand.swift
//  WaveForm
//
//  Created by David Kyslenko on 31.10.2022.
//

import UIKit

struct PathCommand {
    let type: CGPathElementType
    let point: CGPoint
    let controlPoints: [CGPoint]
}
