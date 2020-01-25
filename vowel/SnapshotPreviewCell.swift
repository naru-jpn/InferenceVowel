//
//  SnapshotPreviewCell.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/21.
//

import UIKit

final class SnapshotPreviewCell: UITableViewCell {
    @IBOutlet private var waveView: WaveView! {
        didSet {
            waveView.numDrawnSamples = 16
            waveView.maxY = 15.0
        }
    }

    func set(snapshot: Snapshot) {
        var buffer = snapshot.coefficients
        waveView.set(buffer: &buffer)
    }
}
