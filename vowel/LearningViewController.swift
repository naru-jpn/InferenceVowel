//
//  LearningViewController.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/22.
//

import UIKit
import CoreML

final class LearningViewController: UITableViewController {
    let updatedModelUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("updated.mlmodelc")
    let tempUpdatedModelUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("updated_tmp.mlmodelc")

    private func training() {
        func completion(updateContext: MLUpdateContext) {
            let updatedModel = updateContext.model
            let fileManager = FileManager.default
            do {
                try fileManager.createDirectory(at: tempUpdatedModelUrl, withIntermediateDirectories: true, attributes: nil)
                try updatedModel.write(to: tempUpdatedModelUrl)
                _ = try fileManager.replaceItemAt(updatedModelUrl, withItemAt: tempUpdatedModelUrl)
                print("Updated model saved to:\n\t\(updatedModelUrl)")
            } catch {
                print("Could not save updated model to the file system: \(error)")
                return
            }

            DispatchQueue.main.async { [weak self] in
                let message: String? = updateContext.task.error.flatMap({ $0.localizedDescription })
                let alertController = UIAlertController(title: "Complete Training", message: message, preferredStyle: .alert)
                alertController.addAction(
                    UIAlertAction(title: "OK", style: .default)
                )
                self?.present(alertController, animated: true)
            }
        }

        var featureProviders: [MLFeatureProvider] = []
        for snapshot in SnapshotStore.shared.snapshots {
            let inputValue = snapshot.featureValue
            let outputValue = MLFeatureValue(string: snapshot.vowel.identifier)

            let dataPointFeatures: [String: MLFeatureValue] = ["input": inputValue, "label": outputValue]
            if let provider = try? MLDictionaryFeatureProvider(dictionary: dataPointFeatures) {
                featureProviders.append(provider)
            } else {
                print("Failed to create MLDictionaryFeatureProvider.")
            }
        }
        let batchProvider = MLArrayBatchProvider(array: featureProviders)

        let url = UpdatableKNN.urlOfModelInThisBundle
        guard let updateTask = try? MLUpdateTask(forModelAt: url, trainingData: batchProvider, configuration: nil, completionHandler: completion) else {
            fatalError("Could't create an MLUpdateTask.")
        }
        updateTask.resume()
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            training()
        case 1:
            let viewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "VowelInference")
            present(viewController, animated: true)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
