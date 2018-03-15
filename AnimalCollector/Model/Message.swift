//
//  Message.swift
//  AnimalCollector
//
//  Created by Quang Nguyen on 3/14/18.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import FirebaseAuth

class Message: NSObject {
    var fromId: String?
    var text: String?
    var timestamp: TimeInterval?
    var toId: String?
    
    func chatPartnerId() -> String {
        return (fromId == Auth.auth().currentUser?.uid ? toId : fromId)!
    }
}
