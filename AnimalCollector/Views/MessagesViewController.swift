//
//  MessagesViewController.swift
//  AnimalCollector
//
//  Created by Quang Nguyen on 3/13/18.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class MessagesViewController: UITableViewController {
    // TODO add spinner
    // TODO add logic for not loading spinner when there arent any messages
    
    private let reuseIdentifier = "messagesUserCell"
    
    var messages: [Message]?
    var messagesDictionary: [String: Message]?
    var sv: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(handleNewMessage))
        initView()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: reuseIdentifier)
//        sv = UIViewController.displaySpinner(onView: self.view)
//        observeMessages()
        observeUserMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageViewController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (messages?.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! UserCell
        
        let message = messages![indexPath.row]
        cell.message = message
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages![indexPath.row]
        
        let chatPartnerId: String = message.chatPartnerId()
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        
        ref.observeSingleEvent(of: .value) { (snapshot) in
            let dictionary = snapshot.value as? [String: AnyObject]
            
            let user = User()
            user.id = chatPartnerId
            user.name = dictionary!["email"] as? String
            user.score = dictionary!["score"] as? Int
            
            self.showChatControllerForUser(user: user)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func showChatControllerForUser(user: User) {
        let chatLogController = ChatLogViewController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    func initView() {
        messages = [Message]()
        messagesDictionary = [String: Message]()
    }
    
    func observeUserMessages() {
        let ref: DatabaseReference = Database.database().reference()
        let userMessagesRef = ref.child("user-messages")
        let uid = Auth.auth().currentUser?.uid
        let userRef = userMessagesRef.child(uid!)
        
        userRef.observe(.childAdded) { (snapshot) in
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let message = Message()
                    
                    message.fromId = dictionary["fromId"] as? String
                    message.text = dictionary["text"] as? String
                    message.timestamp = dictionary["timestamp"] as? TimeInterval
                    message.toId = dictionary["toId"] as? String
                    
                    let chatPartnerId = message.chatPartnerId()
                    
                    self.messagesDictionary![chatPartnerId] = message
                    if let values = self.messagesDictionary?.values {
                        self.messages = Array(values)
                        self.messages?.sort {
                            $0.timestamp! > $1.timestamp!
                        }
                    }
                
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
                
                
            })
            
//            UIViewController.removeSpinner(spinner: self.sv!)
        }
    }
    
    // TODO remove?
    func observeMessages() {
        let ref: DatabaseReference = Database.database().reference()
        let messagesRef = ref.child("messages")

        messagesRef.observe(.childAdded) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message()
                
                message.fromId = dictionary["fromId"] as? String
                message.text = dictionary["text"] as? String
                message.timestamp = dictionary["timestamp"] as? TimeInterval
                message.toId = dictionary["toId"] as? String

                if let toId = message.toId {
                    self.messagesDictionary![toId] = message
                    if let values = self.messagesDictionary?.values {
                            self.messages = Array(values)
                        self.messages?.sort {
                            $0.timestamp! > $1.timestamp!
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }

//            UIViewController.removeSpinner(spinner: self.sv!)
        }
    }
}
