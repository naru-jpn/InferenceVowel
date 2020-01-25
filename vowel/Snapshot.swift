//
//  Snapshot.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/21.
//

import Foundation

struct Snapshot: Codable, Equatable {
    let id: String = String(UUID().uuidString.prefix(8))
    let vowel: Vowel
    let coefficients: [Float]
}
