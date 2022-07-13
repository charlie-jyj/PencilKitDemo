//
//  ThumbnailCollectionViewController.swift
//  pencilKitDemo
//
//  Created by 정유진 on 2022/07/11.
//

import UIKit

class ThumbnailCollectionViewController: UICollectionViewController, DataModelControllerObserver {
    
    var dataModelController = DataModelController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // inform the data model of the current thumbnail traits
        dataModelController.thumbnailTraitCollection = traitCollection
        // observe changes to the data model
        dataModelController.observers.append(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        dataModelController.thumbnailTraitCollection = traitCollection
    }
    
    // data model observer
    
    func dataModelChanged() {
        collectionView.reloadData()
    }
    
    // actions
    @IBAction func newSignature(_ sender: Any) {
        dataModelController.newSignature()
    }
    
    // Collection View data source
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("signatures count", dataModelController.signatures.count)
        return dataModelController.signatures.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell",
                                                            for: indexPath) as? ThumbnailCollectionViewCell
        else { fatalError("unexpected cell type")}
        
        if let index = indexPath.last,
           index < dataModelController.thumbnails.count {
            cell.imageView.image = dataModelController.thumbnails[index]
        }
        
        return cell
    }
    
    // Collection View Delegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // create the drawing
        guard let signatureViewController = storyboard?.instantiateViewController(withIdentifier: "SignatureViewController") as? SignatureViewController,
              let navigationController = navigationController else { return }
        
        signatureViewController.dataModelController = dataModelController
        signatureViewController.signatureIndex = indexPath.last!
        navigationController.modalPresentationStyle = .overCurrentContext
        navigationController.present(signatureViewController, animated: true)
    }

}

