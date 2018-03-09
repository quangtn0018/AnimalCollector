//
//  MyProfileCollectionViewCell.swift
//  AnimalCollector
//
//  Created by Quang Nguyen on 3/7/18.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import SDWebImage

class MyProfileCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var animalImage: UIImageView!
    @IBOutlet weak var animalName: UILabel!
    @IBOutlet weak var animalScore: UILabel!
    
    func displayContent(imageURL: String, name: String, score: Int) {
        animalImage.sd_setImage(with: URL(string: imageURL), completed: nil)
        animalName.text = name
        animalScore.text = "\(score)"
    }
}
