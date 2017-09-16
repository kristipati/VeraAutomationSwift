//
//  BaseCell.swift
//  Automation
//
//  Created by Scott Gruby on 11/2/14.
//  Copyright (c) 2014 Gruby Solutions. All rights reserved.
//

import UIKit

class BaseCell: UICollectionViewCell {
    weak var delegate: DeviceCellProtocol?
    var device: VeraDevice?
    var scene: VeraScene?

    var layerAdded = false
    func setup() {
        if layerAdded == false {
            layerAdded = true
            layer.cornerRadius = 5.0
            let bgLayer = blueGradientLayer()
            bgLayer.frame = bounds
            layer.insertSublayer(bgLayer, at: 0)
        }
    }

    func blueGradientLayer() -> CAGradientLayer {
        let colorOne = UIColor.white
        let colorTwo = UIColor(red: 176.0/255.0, green: 224.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        let colors = [colorOne.cgColor, colorTwo.cgColor]
        let stopOne = NSNumber(value: 0.0 as Double)
        let stopTwo = NSNumber(value: 1.0 as Double)
        let locations = [stopOne, stopTwo]

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.locations = locations

        return gradientLayer
    }
}
