//
//  SnapshotPreviewSectionHeader.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/21.
//

import UIKit

final class SnapshotPreviewSectionHeader: UITableViewCell {
    @IBOutlet private var titleLabl: UILabel!

    func set(title: String) {
        titleLabl.text = title
    }
}
