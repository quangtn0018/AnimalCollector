//
//  NewMessageViewController.swift
//  AnimalCollector
//
//  Created by Quang Nguyen on 3/13/18.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class NewMessageViewController: UITableViewController {
    private let reuseIdentifier = "newMessageCell"
    
    var curUserUID: String?
    var users: [User]?
    var sv: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        initView()
        
        tableView.register(LeaderboardsUserCell.self, forCellReuseIdentifier: reuseIdentifier)
        sv = UIViewController.displaySpinner(onView: self.view)
        
        self.curUserUID = Auth.auth().currentUser?.uid
        fetchUsers()
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (users?.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let user = users![indexPath.row]
        
        cell.textLabel?.text = user.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var messagesController: MessagesViewController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            let user = self.users![indexPath.row]
            self.messagesController?.showChatControllerForUser(user: user)
        }
    }
    
    func initView() {
        users = [User]()
    }
    
    func fetchUsers() {
        let ref: DatabaseReference = Database.database().reference()
        let usersRef = ref.child("users")
        
        usersRef.observe(DataEventType .childAdded) { (snapshot) in
            
            if snapshot.key == self.curUserUID {
                return
            }
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = User()
                user.name = dictionary["email"] as? String
                user.id = snapshot.key
                
                self.users?.append(user)
                self.users?.sort {
                    $0.name! < $1.name!
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
            UIViewController.removeSpinner(spinner: self.sv!)
        }
    }
}
