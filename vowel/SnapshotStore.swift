//
//  SnapshotStore.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/21.
//

import Foundation

final class SnapshotStore {
    static let shared = SnapshotStore()
    private let storedUrl: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("snapshot.dat")

    private(set) var snapshots: [Snapshot] = []

    init() {
        loadSnapshots()
    }

    func append(snapshot: Snapshot) {
        snapshots.append(snapshot)
        saveSnapshots()
    }

    func remove(snapshot: Snapshot) -> Bool {
        if let index = snapshots.firstIndex(of: snapshot) {
            snapshots.remove(at: index)
            saveSnapshots()
            return true
        } else {
            return false
        }
    }

    func removeAll() {
        snapshots = []
        saveSnapshots()
    }

    func snapshots(with vowel: Vowel) -> [Snapshot] {
        snapshots.filter({ $0.vowel == vowel })
    }

    private func loadSnapshots() {
        guard let data = try? Data(contentsOf: storedUrl) else {
            debugPrint("Faile to load snapshots data from local storage.")
            return
        }
        let decoder = JSONDecoder()
        do {
            snapshots = try decoder.decode([Snapshot].self, from: data)
        } catch {
            debugPrint("Faile to load snapshots.")
        }
    }

    private func saveSnapshots() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(snapshots)
            try data.write(to: storedUrl, options: .atomic)
        } catch {
            debugPrint("Faile to save snapshots.")
        }
    }
}
