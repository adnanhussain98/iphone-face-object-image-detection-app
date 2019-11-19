//
//  HomePage.swift
//  PhotoAlbum
//
//  Created by Adnan Hussain on 05/04/2019.
//  Copyright © 2019 Adnan Hussain. All rights reserved.
//

import UIKit

class HomePage: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //takes user to image detection view controller
    @IBAction func imageDetectionButton(_ sender: Any) {
        performSegue(withIdentifier: "imageDetection", sender: self)
    }
    
    //takes user to live detection view controller
    @IBAction func liveDetectionButton(_ sender: Any) {
        performSegue(withIdentifier: "liveDetection", sender: self)
    }
    

}
