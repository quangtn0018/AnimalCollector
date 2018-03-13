//
//  AnimalData.swift
//  AnimalCollector
//
//  Created by Quang Nguyen on 3/8/18.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit

class AnimalData {
    var key: String
    var imageName: String
    var imageURL: String
    var score: Int
    
    init(key: String, imageName: String, imageURL: String, score: Int) {
        self.key = key
        self.imageName = imageName
        self.imageURL = imageURL
        self.score = score
    }

}
