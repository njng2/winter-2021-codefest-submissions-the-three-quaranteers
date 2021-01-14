//
//  ViewController.swift
//  codefest
//
//  Created by Nancy Ng  on 1/11/21.
//

import UIKit
import GoogleMaps



class ViewController: UIViewController {
  
    @IBOutlet weak var google_maps: GMSMapView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.camera(withLatitude: 40.730610, longitude:  -73.935242, zoom: 10)
    
        
        let mapview = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapview
        
   
    }
 
   
    
   
    



}
