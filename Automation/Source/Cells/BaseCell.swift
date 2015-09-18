//
//  BaseCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class BaseCell: UICollectionViewCell {
    var layerAdded = false
    func setup() {
        if self.layerAdded == false {
            self.layerAdded = true
            self.layer.cornerRadius = 5.0
            let bgLayer = self.blueGradientLayer()
            bgLayer.frame = self.bounds
            self.layer.insertSublayer(bgLayer, atIndex: 0)
        }
    }
    
    func blueGradientLayer()->CAGradientLayer {
        let colorOne = UIColor.whiteColor()
        let colorTwo = UIColor(red: 176.0/255.0, green: 224.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        let colors = [colorOne.CGColor, colorTwo.CGColor]
        let stopOne = NSNumber(double: 0.0)
        let stopTwo = NSNumber(double: 1.0)
        let locations = [stopOne, stopTwo]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        
        return gradientLayer
    }
}
