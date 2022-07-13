//
//  DataModel.swift
//  pencilKitDemo
//
//  Created by 정유진 on 2022/07/12.
//

import UIKit
import PencilKit
import os

struct DataModel: Codable {
    
    static let defaultSignatureNames: [String] = [] // drawing assets
    static let canvasWidth: CGFloat = 768
    var signatures: [PKDrawing] = []
    var base64s: [String] = []
}

protocol DataModelControllerObserver {
    func dataModelChanged()
}

class DataModelController {
    
    var dataModel = DataModel() // the underlying data model
    
    var thumbnails = [UIImage]()
    var thumbnailTraitCollection = UITraitCollection() {
        didSet {
            if oldValue.userInterfaceStyle != thumbnailTraitCollection.userInterfaceStyle {
                generateAllThumbnails()
            }
        }
    }
    
    private let thumbnailQueue = DispatchQueue(label: "ThumbnailQueue", qos: .background)
    private let serializationQueue = DispatchQueue(label: "SerializationQueue", qos: .background)
    
    // viewController 
    var observers = [DataModelControllerObserver]()
    
    static let thumbnailSize = CGSize(width: 192, height: 256)
    
    var signatures: [PKDrawing] {
        get { dataModel.signatures }
        set { dataModel.signatures = newValue }
    }
    
    
    init() {
        loadDataModel()
    }
    
    func updateSignatures(_ signature: PKDrawing, at index: Int) {
        dataModel.signatures[index] = signature
        generateThumbnail(index)
        saveDataModel()
    }
    
    private func generateAllThumbnails() {
        for index in signatures.indices {
            generateThumbnail(index)
        }
    }
    
    private func generateThumbnail(_ index: Int) {
        let signature = signatures[index]
        let aspectRatio = DataModelController.thumbnailSize.width / DataModelController.thumbnailSize.height
        let thumbnailRect = CGRect(x: 0, y: 0, width: DataModel.canvasWidth, height: DataModel.canvasWidth / aspectRatio)
        let thumbnailScale = UIScreen.main.scale * DataModelController.thumbnailSize.width / DataModel.canvasWidth
        let traitCollection = thumbnailTraitCollection
        
        thumbnailQueue.async {
            traitCollection.performAsCurrent {
                let image = signature.image(from: thumbnailRect, scale: thumbnailScale)
                
                // image base64 변환하기
                if let data = image.pngData() {
                    let base64 = data.base64EncodedString()
                    self.dataModel.base64s[index] = base64
                }
                
                DispatchQueue.main.async {
                    self.updateThumbnail(image, at: index)
                }
            }
        }
    }
    
    private func updateThumbnail(_ image: UIImage, at index: Int) {
        thumbnails[index] = image
        didChange()
    }
    
    private func didChange() {
        for observer in self.observers {
            observer.dataModelChanged()
        }
    }
    
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths.first!
        return documentsDirectory.appendingPathComponent("PencilKitDraw.data")
    }
    
    func saveDataModel() {
        let savingDataModel = dataModel
        let url = saveURL
        serializationQueue.async {
            do {
                let encoder = PropertyListEncoder()
                let data = try encoder.encode(savingDataModel)
                try data.write(to: url)
            } catch {
                os_log("Could not save data model: %s", type: .error, error.localizedDescription)
            }
        }
    }
    
    private func loadDataModel() {
        let url = saveURL
        serializationQueue.async {
            let dataModel: DataModel
            
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let decoder = PropertyListDecoder()
                    let data = try Data(contentsOf: url)
                    dataModel = try decoder.decode(DataModel.self, from: data)
                } catch {
                    os_log("Could not load data model: %s", type: .error, error.localizedDescription)
                    dataModel = self.loadDefaultDrawings()
                }
            } else {
                dataModel = self.loadDefaultDrawings()
            }
            
            DispatchQueue.main.async {
                self.setLoadedDataModel(dataModel)
            }
        }
    }
    
    private func loadDefaultDrawings() -> DataModel {
        var testDataModel = DataModel()
        for sampleDataName in DataModel.defaultSignatureNames {
            guard let data = NSDataAsset(name: sampleDataName)?.data else { continue }
            if let sign = try? PKDrawing(data: data) {
                testDataModel.signatures.append(sign)
            }
        }
        return testDataModel
    }
    
    private func setLoadedDataModel(_ dataModel: DataModel) {
        self.dataModel = dataModel
        thumbnails = Array(repeating: UIImage(), count: dataModel.signatures.count)
        generateAllThumbnails()
    }
    
    func newSignature() {
        let newSignature = PKDrawing()
        dataModel.signatures.append(newSignature)
        dataModel.base64s.append("")
        thumbnails.append(UIImage())
        updateSignatures(newSignature, at: dataModel.signatures.count - 1)
    }
}
