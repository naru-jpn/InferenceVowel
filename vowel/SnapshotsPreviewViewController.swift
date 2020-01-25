//
//  SnapshotsPreviewViewController.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/21.
//

import UIKit

final class SnapshotsPreviewViewController: UITableViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @IBAction private func didTapTrashItem() {
        guard SnapshotStore.shared.snapshots.count > 0 else {
            return
        }
        confirmDeleteAll()
    }

    private func delete(snapshot: Snapshot, at indexPath: IndexPath) {
        if SnapshotStore.shared.remove(snapshot: snapshot) {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }

    private func confirmDeleteAll() {
        let alertContrller = UIAlertController(title: "Delete All", message: "Will you delete all snapshot?", preferredStyle: .alert)
        alertContrller.addAction(
            UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deleteAll()
            })
        )
        alertContrller.addAction(
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        )
        present(alertContrller, animated: true)
    }

    private func deleteAll() {
        SnapshotStore.shared.removeAll()
        tableView.reloadData()
    }

    // MARK: UITableViewDelegate / UITableViewDatasource

    override func numberOfSections(in tableView: UITableView) -> Int {
        Vowel.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SnapshotStore.shared.snapshots(with: Vowel.allCases[section]).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "preview_snapshot", for: indexPath) as! SnapshotPreviewCell
        let snapshot = SnapshotStore.shared.snapshots(with: Vowel.allCases[indexPath.section])[indexPath.row]
        cell.set(snapshot: snapshot)
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCell(withIdentifier: "preview_snapshot_header") as! SnapshotPreviewSectionHeader
        header.set(title: Vowel.allCases[section].displayName)
        return header.contentView
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let snapshot = SnapshotStore.shared.snapshots(with: Vowel.allCases[indexPath.section])[indexPath.row]
            delete(snapshot: snapshot, at: indexPath)
        default:
            break
        }
    }
}
