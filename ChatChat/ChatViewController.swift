/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import Firebase
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
  
    //Array to store various instances of JSQMessage in the app
    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    let rootRef = Firebase(url: "https://chatchat-baralabs.firebaseio.com")
    var messageRef: Firebase!
    //Create a reference that tracks whether the local user is typing.
    var userIsTypingRef: Firebase!
    //Store whether the local user is typing in a private property
    private var localTyping = false
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            //Using a computed property, you can update userIsTypingRef each time you update this property
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    //This property holds an FQuery, which is just like a Firebase reference, except that it’s ordered by an order function
    var usersTypingQuery: FQuery!
    
    
    
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ChatChat"
    setupBubbles()
    
    //No avatars
    collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
    collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
    
    messageRef = rootRef.childByAppendingPath("messages")
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    //Watch for new messages
    observeMessages()
    //Watch for the user typing
    observeTyping()
    
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
  }
    
    // MARK: - Observe Typing
    
    private func observeTyping() {
        //This method creates a reference to the URL of /typingIndicator, 
        //which is where you’ll update the typing status of the user
        let typingIndicatorRef = rootRef.childByAppendingPath("typingIndicator")
        userIsTypingRef = typingIndicatorRef.childByAppendingPath(senderId)
        //Delete it once the user has left using onDisconnectRemoveValue()
        userIsTypingRef.onDisconnectRemoveValue()
        
        //You initialize the query by retrieving all users who are typing.
        //This is basically saying, “Hey Firebase, go to the key /typingIndicators and get me all users for whom the value is true.”
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
        //Observe for changes using .Value; this will give you an update anytime anything changes
        usersTypingQuery.observeEventType(.Value) { (data: FDataSnapshot!) in
            //You're the only typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            //If there are more than zero users, and the local user isn’t typing, it’s safe to set the indicator. 
            //Call scrollToBottomAnimated(_:animated:) to ensure the indicator is displayed
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottomAnimated(true)
        }
    }
    
    // MARK: - Delegate Methods
    
    //Just like cellForRowAtIndexPath but for message data
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        //Here you retrieve the message based on the NSIndexPath item.
        let message = messages[indexPath.item]
        
        //Check if the message was sent by the local user. If so, return the outgoing image view.
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            //If the message was not sent by the local user, return the incoming image view.
            return incomingBubbleImageView
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView!.textColor = UIColor.blackColor()
        }
        
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        //remove avatar support and close the gap where the avatars would normally get displayed
        return nil
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        //create a child reference with a unique key
        let itemRef = messageRef.childByAutoId()
        //Create a dictionary to represent the message. A [String: AnyObject] works as a JSON-like object.
        let messageItem = ["text": text, "senderId": senderId]
        //Save the value at the new child location.
        itemRef.setValue(messageItem)
        //Play the canonical “message sent” sound.
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        //Complete the “send” action and reset the input toolbar to empty.
        finishSendingMessage()
        
        //Reset the typing indicator
        isTyping = false
        
    }
    
    private func observeMessages() {
        //Start by creating a query that limits the synchronization to the last 25 messages.
        let messagesQuery = messageRef.queryLimitedToLast(25)
        //Use the .ChildAdded event to observe for every child item that has been added, and will be added, at the messages location
        messagesQuery.observeEventType(.ChildAdded) { (snapshot: FDataSnapshot!) in
            //Extract the senderId and text from snapshot.value
            let id = snapshot.value["senderId"] as! String
            let text = snapshot.value["text"] as! String
            
            //Call addMessage() to add the new message to the data source
            self.addMessage(id, text: text)
            //Inform JSQMessagesViewController that a message has been received
            self.finishReceivingMessage()
        }
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        //If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    func addMessage(id: String, text: String) {
        //Creates a new JSQMessage with a blank displayName and adds it to the data source.
        let message = JSQMessage(senderId: id, displayName: "", text: text)
        messages.append(message)
    }
}