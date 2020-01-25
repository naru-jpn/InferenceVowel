//
//  Vowel.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/21.
//

import Foundation

enum Vowel: Int, Codable, CaseIterable {
    case a, i, u, e, o, unknown

    var identifier: String {
        switch self {
        case .a:
            return "a"
        case .i:
            return "i"
        case .u:
            return "u"
        case .e:
            return "e"
        case .o:
            return "o"
        case .unknown:
            return "unknown"
        }
    }

    var displayName: String {
        identifier
    }

    static func vowel(with identifier: String) -> Vowel? {
        switch identifier {
        case "a":
            return .a
        case "i":
            return .i
        case "u":
            return .u
        case "e":
            return .e
        case "o":
            return .o
        case "unknown":
            return .unknown
        default:
            return nil
        }
    }
}
