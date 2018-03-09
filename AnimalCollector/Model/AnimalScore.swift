//
//  Animals.swift
//  AnimalCollector
//
//  Created by Quang Nguyen on 2/12/18.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit

class AnimalScore {
    var animals: [String: Animal]
    
    struct Animal {
        var score: Int = 0
    }
    
    init() {
        animals = [
            "sloth": Animal(score: 10),
            "monkey": Animal(score: 10),
            "tiger": Animal(score: 11),
            "lion": Animal(score: 11),
            "bear": Animal(score: 11),
            "eagle": Animal(score: 11),
            "fox": Animal(score: 11),
            "turtle": Animal(score: 11),
            "lemur": Animal(score: 11),
            // TODO for test remove later
            "jackfruit": Animal(score: 100)
        ]
    }
}
