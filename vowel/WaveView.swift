//
//  WaveView.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/20.
//

import UIKit

final class WaveView: UIView {
    var numDrawnSamples: Int = 2 {
        didSet {
            buffer = unsafeBitCast(malloc(MemoryLayout<Float>.stride * numDrawnSamples), to: UnsafeMutablePointer<Float>.self)
        }
    }
    var buffer = unsafeBitCast(malloc(MemoryLayout<Float>.stride * 2), to: UnsafeMutablePointer<Float>.self)
    var maxY: Float = 1.0
    var position: CGFloat = 0.0 // -1.0 ~ 1.0

    deinit {
        free(buffer)
    }

    func set(buffer: UnsafeMutablePointer<Float>) {
        memcpy(self.buffer, buffer, MemoryLayout<Float>.stride * numDrawnSamples)
        self.setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.setLineWidth(1)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)
        context.setStrokeColor(UIColor.green.cgColor)

        let d: CGFloat = rect.size.width / CGFloat(numDrawnSamples - 1)
        let point = CGPoint(x: 0, y: rect.size.height / 2 * (position + CGFloat(1 - buffer[0] / maxY)))
        context.move(to: point)
        for i in 1..<numDrawnSamples {
            let point = CGPoint(x: d * CGFloat(i), y: rect.size.height / 2 * (position + CGFloat(1 - buffer[i] / maxY)))
            context.addLine(to: point)
        }
        context.strokePath()
    }
}
