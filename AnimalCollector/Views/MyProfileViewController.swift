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

class MyProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var totalScore: UILabel!
    
    private let reuseIdentifier = "myProfileCollectionViewCell"
    var curUserUID: String?
    var userCollections: [AnimalData]?
    var collectionsRefToRemove: DatabaseReference?
    var userCollectionsKeysToIndex: [String: Int]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
        initView()
        fetchUserScore()
        fetchUserCollections()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        collectionsRefToRemove?.removeAllObservers()
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
    
    func initView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        userCollections = [AnimalData]()
        userCollectionsKeysToIndex = [String: Int]()
    }
    
    func fetchUserScore() {
        let ref: DatabaseReference = Database.database().reference()
        let usersRef = ref.child("users")
        let curUserRef = usersRef.child(curUserUID!)
        let scoreRef = curUserRef.child("score")

        
        scoreRef.observe(DataEventType.value, with: { (snapshot) in
            if let score = snapshot.value as? Int {
                self.totalScore.text = "Total score: \(score)"
            }
        })
        
    }
    
    func fetchUserCollections() {
        let ref: DatabaseReference = Database.database().reference()
        let usersRef = ref.child("users")
        let curUserRef = usersRef.child(curUserUID!)
        let collectionsRef = curUserRef.child("collections")
        collectionsRefToRemove = collectionsRef
        
        
        collectionsRef.observe(DataEventType.value, with: { (snapshot) in
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
                
                // add to userCollections if key doesnt exist
                if self.userCollectionsKeysToIndex![collectionKey!] == nil {
                    self.userCollectionsKeysToIndex![collectionKey!] = self.userCollections?.count
                    self.userCollections?.append(AnimalData(key: collectionKey!, imageName: collectionImageName!, imageURL: collectionImageURL!, score: collectionScore!))
                }
                else {
                    let index: Int = self.userCollectionsKeysToIndex![collectionKey!]!
                    // update old image with new one if key exists
                    if (self.userCollections![index]).imageURL != collectionImageURL {
                        self.userCollections![index].imageURL = collectionImageURL!
                    }
                }
                
            }
            
            // reload collection view data after usersCollection has been set
            // need to do this because firebase db runs async
            DispatchQueue.main.async {
                self.collectionView.reloadData()
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

