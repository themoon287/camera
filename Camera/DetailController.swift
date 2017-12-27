//
//  DetailController.swift
//  Camera
//
//  Created by Khuất Hằng on 12/21/17.
//  Copyright © 2017 Tribal Media House. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

class DetailController: UIViewController {
    
    var account: AccountModel = AccountModel()
    
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var birth: UILabel!
    override func viewDidLoad() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.schemebtn))
        logoButton.isUserInteractionEnabled = true
        logoButton.addGestureRecognizer(tapGestureRecognizer)
        
        //avatar and screen name
            
            if self.account.avatar != "" {
                avatar.sd_setImage(with: NSURL(string: self.account.avatar) as URL?)
                avatar.contentMode = UIViewContentMode.scaleAspectFit
            } else {
                avatar.image = UIImage(named: "no_image")
            }
        name.text = self.account.name
        email.text = self.account.email
        birth.text = self.account.birth
    }
    
    @IBOutlet weak var logoButton: UIImageView!
    @IBAction func backView(_ sender: Any) {
       self.navigationController?.popViewController(animated: true) 
    }
    
    @objc func schemebtn() {
        var url: URL?
        var link: URL?
        
        url = NSURL(string: "fb://profile/" + self.account.id)! as URL
        
        if url != nil {
            if (UIApplication.shared.canOpenURL(url!)) {
                UIApplication.shared.openURL(url!)
            }
        }
       
    }
}
