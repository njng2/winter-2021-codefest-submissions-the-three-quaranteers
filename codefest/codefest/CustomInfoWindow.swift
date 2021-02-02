//
//  CustomInfoWindow.swift
//  codefest
//
//  Created by Patrick Chaca on 2/1/21.
//

import UIKit
import Foundation
import Cosmos
class CustomInfoWindow: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
     
    */
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var accessibility: UILabel!
    @IBOutlet weak var hygiene: UILabel!
    @IBOutlet weak var capacity: UILabel!
    @IBOutlet weak var stars: CosmosView!
    weak var delegate: CustomInfoWindow?
    var spotData: NSDictionary?
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    class func instanceFromNib() -> UIView {
            return UINib(nibName: "CustomInfoWindow", bundle: nil).instantiate(withOwner: self, options: nil).first as! UIView
        }


}
