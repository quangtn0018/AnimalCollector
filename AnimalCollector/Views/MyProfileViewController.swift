//
//  MyProfileViewController.swift
//  AnimalCollector
//
//  Created by Quang Nguyen on 3/7/18.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

private let reuseIdentifier = "myProfileCollectionViewCell"

class MyProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var curUserUID: String?
    var userCollections: [AnimalData]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
        userCollections = [AnimalData]()
        fetchUserCollections()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (userCollections?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MyProfileCollectionViewCell
        
        let collection = userCollections![indexPath.row]
    
        cell.displayContent(imageURL: collection.imageURL, name: collection.key, score: collection.score)
        
        return cell
    }
    
    func fetchUserCollections() {
        let ref: DatabaseReference = Database.database().reference()
        let usersRef = ref.child("users")
        let curUserRef = usersRef.child(curUserUID!)
        let collectionsRef = curUserRef.child("collections")
        
        collectionsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let collections = snapshot.value as? NSDictionary
            if (collections == nil) {
                return
            }
            
            for (_, value) in collections! {
                let collection = value as? NSDictionary
                let collectionKey = collection?.value(forKey: "key") as? String
                let collectionImageName = collection?.value(forKey: "imageName") as? String
                let collectionImageURL = collection?.value(forKey: "imageURL") as? String
                let collectionScore = collection?.value(forKey: "score") as? Int
                self.userCollections?.append(AnimalData(key: collectionKey!, imageName: collectionImageName!, imageURL: collectionImageURL!, score: collectionScore!))
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func checkIfUserIsLoggedIn() {
        if let currentUser = Auth.auth().currentUser {
            self.curUserUID = currentUser.uid
        } else {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginViewController = LoginViewController()
        present(loginViewController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
