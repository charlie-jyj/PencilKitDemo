//
//  ThumbnailCollectionViewCell.swift
//  pencilKitDemo
//
//  Created by 정유진 on 2022/07/11.
//

import UIKit

class ThumbnailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    
    // set up the view initially
    override func awakeFromNib() {
        super.awakeFromNib()
        // Give the view a shadow.
        imageView.layer.shadowPath = UIBezierPath(rect: imageView.bounds).cgPath
        imageView.layer.shadowOpacity = 0.2
        imageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        imageView.clipsToBounds = false
    }
}
