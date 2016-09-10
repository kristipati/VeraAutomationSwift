//
//  SFSwiftNotification.swift
//  SFSwiftNotification
//
//  Created by Simone Ferrini on 13/07/14.
//  Copyright (c) 2014 sferrini. All rights reserved.
//

import UIKit

enum AnimationType {
    case animationTypeCollision
    case animationTypeBounce
}

struct AnimationSettings {
    var duration:TimeInterval = 0.5
    var delay:TimeInterval = 0
    var damping:CGFloat = 0.6
    var velocity:CGFloat = 0.9
    var elasticity:CGFloat = 0.3
}

enum Direction {
    case topToBottom
    case leftToRight
    case rightToLeft
}

protocol SFSwiftNotificationProtocol {
    func didNotifyFinishedAnimation(_ results: Bool)
    func didTapNotification()
}

class SFSwiftNotification: UIView, UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate {
    
    var label = UILabel()
    var animationType:AnimationType?
    var animationSettings = AnimationSettings()
    var direction:Direction?
    var dynamicAnimator = UIDynamicAnimator()
    var delegate: SFSwiftNotificationProtocol?
    var canNotify = true
    var offScreenFrame = CGRect()
    var toFrame = CGRect()
    var delay = TimeInterval()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(viewController: UIViewController, title: NSString?, animationType:AnimationType, direction:Direction, delegate: SFSwiftNotificationProtocol?) {
        var frame = viewController.view.frame
        frame.size.height = 64
        self.toFrame = frame
        super.init(frame: frame)
        
        self.animationType = animationType
        self.direction = direction
        self.delegate = delegate
        
        var newFrame = self.frame
        newFrame.insetInPlace(dx: 20, dy: 0)
        label = UILabel(frame: newFrame)
        label.text = title as? String
        label.textAlignment = NSTextAlignment.center
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        self.addSubview(label)
        
        // Create gesture recognizer to detect notification touches
        let tapReconizer = UITapGestureRecognizer()
        tapReconizer.addTarget(self, action: #selector(SFSwiftNotification.invokeTapAction));
        
        // Add Touch recognizer to notification view
        self.addGestureRecognizer(tapReconizer)
        
        offScreen()
        
        viewController.view.addSubview(self)
        
        //Don't forget this line
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func invokeTapAction() {
        
        if self.delegate != nil {
            self.delegate!.didTapNotification()
            self.canNotify = true
        }
    }
    
    func offScreen() {
        
        self.offScreenFrame = self.frame
        
        switch direction! {
        case .topToBottom:
            self.offScreenFrame.origin.y = -self.frame.size.height
        case .leftToRight:
            self.offScreenFrame.origin.x = -self.frame.size.width
        case .rightToLeft:
            self.offScreenFrame.origin.x = +self.frame.size.width
        }
        
        self.frame = offScreenFrame
    }
    
    func animate(_ delay:TimeInterval) {
        
        self.delay = delay
        
        if canNotify {
            self.canNotify = false
            
            switch self.animationType! {
            case .animationTypeCollision:
                setupCollisionAnimation(toFrame)
                
            case .animationTypeBounce:
                setupBounceAnimation(toFrame, delay: delay)
            }
        }
    }
    
    func setupCollisionAnimation(_ toFrame:CGRect) {
        
        self.dynamicAnimator = UIDynamicAnimator(referenceView: self.superview!)
        self.dynamicAnimator.delegate = self
        
        let elasticityBehavior = UIDynamicItemBehavior(items: [self])
        elasticityBehavior.elasticity = animationSettings.elasticity;
        self.dynamicAnimator.addBehavior(elasticityBehavior)
        
        let gravityBehavior = UIGravityBehavior(items: [self])
        self.dynamicAnimator.addBehavior(gravityBehavior)
        
        let collisionBehavior = UICollisionBehavior(items: [self])
        collisionBehavior.collisionDelegate = self
        self.dynamicAnimator.addBehavior(collisionBehavior)
        
        collisionBehavior.addBoundary(withIdentifier: "BoundaryIdentifierBottom" as NSCopying, from: CGPoint(x: -self.frame.width, y: self.frame.height+0.5), to: CGPoint(x: self.frame.width*2, y: self.frame.height+0.5))
        
        switch self.direction! {
        case .topToBottom:
            break
        case .leftToRight:
            collisionBehavior.addBoundary(withIdentifier: "BoundaryIdentifierRight" as NSCopying, from: CGPoint(x: self.toFrame.width+0.5, y: 0), to: CGPoint(x: self.toFrame.width+0.5, y: self.toFrame.height))
            gravityBehavior.gravityDirection = CGVector(dx: 10, dy: 1)
        case .rightToLeft:
            collisionBehavior.addBoundary(withIdentifier: "BoundaryIdentifierLeft" as NSCopying, from: CGPoint(x: -0.5, y: 0), to: CGPoint(x: -0.5, y: self.toFrame.height))
            gravityBehavior.gravityDirection = CGVector(dx: -10, dy: 1)
        }
    }
    
    func setupBounceAnimation(_ toFrame:CGRect , delay:TimeInterval) {
        
        UIView.animate(withDuration: animationSettings.duration,
            delay: animationSettings.delay,
            usingSpringWithDamping: animationSettings.damping,
            initialSpringVelocity: animationSettings.velocity,
            options: ([.beginFromCurrentState, .allowUserInteraction]),
            animations:{
                self.frame = toFrame
            }, completion: {
                (value: Bool) in
                self.hide(delay)
            }
        )
    }
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        
        hide(self.delay)
    }
    
    func hide(_ delay:TimeInterval? = nil) {
        if (delay == nil) {
            self.removeFromSuperview()
        } else {
            UIView.animate(withDuration: animationSettings.duration,
                delay: delay!,
                usingSpringWithDamping: animationSettings.damping,
                initialSpringVelocity: animationSettings.velocity,
                options: ([.beginFromCurrentState, .allowUserInteraction]),
                animations:{
                    self.frame = self.offScreenFrame
                }, completion: {
                    (value: Bool) in
                    if self.delegate != nil {
                        self.delegate!.didNotifyFinishedAnimation(true)
                    }
                    self.canNotify = true
                    self.removeFromSuperview()
                }
            )
        }
    }
}
