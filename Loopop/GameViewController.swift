//
//  GameViewController.swift
//  Loopop
//
//  Created by Bryan Johnson on 1/30/16.
//  Copyright (c) 2016 Lucy Johnson. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    var panPointReference: CGPoint?
    var scene: GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = false
        
        /* Set the scale mode to scale to fit the window */
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        skView.presentScene(scene)
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    @IBAction func tapped(sender: UITapGestureRecognizer) {
        if sender.numberOfTouches() == 1 {
            self.scene.movePopper(sender.locationInView(self.view))
        }
        else {
            self.scene.newBalloon(sender.locationInView(self.view), pressState: sender.state, immediate: true)
        }
    }

    @IBAction func longPress(sender: UILongPressGestureRecognizer) {
        self.scene.newBalloon(sender.locationInView(self.view), pressState: sender.state)
    }
    
    @IBAction func panned(sender: UIPanGestureRecognizer) {
        self.scene.movePopper(sender.locationInView(self.view))        
    }
}
