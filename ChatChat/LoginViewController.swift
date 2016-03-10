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

class LoginViewController: UIViewController {
    
    var ref: Firebase!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    ref = Firebase(url: "https://chatchat-baralabs.firebaseio.com")
  }

  @IBAction func loginDidTouch(sender: AnyObject) {
    
    //Login anonymous user
    ref.authAnonymouslyWithCompletionBlock { (error, authData) in
        if error != nil {
            print(error.description)
            return
        } else {
            self.performSegueWithIdentifier("LoginToChat", sender: nil)
        }
    }

  }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        //Retrieve the destination view controller from segue and cast it to a UINavigationController.
        let navVc = segue.destinationViewController as! UINavigationController
        //Cast the first view controller of the UINavigationController as ChatViewController.
        let chatVc = navVc.viewControllers.first as! ChatViewController
        
        //Assign the local user’s ID to chatVc.senderId; this is the local ID that JSQMessagesViewController uses to coordinate messages.
        chatVc.senderId = ref.authData.uid
        //Make chatVc.senderDisplayName an empty string, since this is an anonymous chat room.
        chatVc.senderDisplayName = ""
    }
  
}

