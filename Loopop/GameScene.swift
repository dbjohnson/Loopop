//
//  GameScene.swift
//  Loopop
//
//  Created by Bryan Johnson on 1/30/16.
//  Copyright (c) 2016 Lucy Johnson. All rights reserved.
//

import SpriteKit
import AVFoundation


// global var so it doesn't go out of scope (and stop playing) as soon as we pop a baloon
var audioPlayer: AVAudioPlayer?


class Balloon: SKSpriteNode {
    let popSound = NSDataAsset(name: "Pop")!
    let blowSound = NSDataAsset(name: "Blow")!
    
    func inflate() {
        self.playSound(blowSound)
        let action = SKAction.scaleBy(1.5, duration: 1)
        self.runAction(SKAction.repeatActionForever(action))
    }
    
    func floatAway() {
        self.removeAllActions()
        if let ap = audioPlayer {
            ap.stop()
        }
        let dx = CGFloat(arc4random_uniform(20))
        let dy = CGFloat(arc4random_uniform(50))
        let action = SKAction.moveBy(CGVectorMake(dx, dy), duration: 1)
        self.runAction(SKAction.repeatActionForever(action))
    }
    
    func pop() {
        self.playSound(self.popSound)
        self.removeFromParent()
    }
    
    func playSound(soundAsset: NSDataAsset) {
        do {
            audioPlayer = try AVAudioPlayer(data: soundAsset.data)
            if soundAsset == self.blowSound {
                audioPlayer!.numberOfLoops = -1
            }
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
        } catch {
            print("No sound found")
        }
    }
    
}

class GameScene: SKScene {
    let popperAssets = ["Beak", "Carrot", "Knife", "Mountain", "Needle", "Pencil", "Scissors", "Sword"]
    let balloonAssets = ["Heart", "Purple", "Pink", "Blue", "Green", "Yellow"]
    
    var popper: SKSpriteNode!
    
    override func didMoveToView(view: SKView) {
        self.anchorPoint = CGPointMake(0, 0)
        let background = SKSpriteNode(imageNamed:"Background")
        background.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        background.size = self.frame.size;
        self.addChild(background)
        
        self.popper = SKSpriteNode(imageNamed:"Pencil")
        self.popper.anchorPoint = CGPointMake(0.5, 1.0)
        self.popper.xScale = 0.15
        self.popper.yScale = 0.15
        self.popper.position = background.position
        self.popper.zPosition = 1000
        self.addChild(popper)
    }

    override func update(currentTime: CFTimeInterval) {
        for balloon: Balloon in self.balloons() {
            if balloon.containsPoint(self.popper.position) {
                balloon.pop()
            }
            else if !self.frame.intersects(balloon.frame) {
                balloon.removeFromParent()
            }
        }
    }

    func movePopper(location: CGPoint) {
        self.popper.position = self.convertPointToView(location)
        for balloon: Balloon in self.balloons() {
            if balloon.containsPoint(self.popper.position) {
                balloon.pop()
            }
        }
    }
    
    func balloons() -> Array<Balloon> {
        return self.children.flatMap{$0 as? Balloon}
    }

    func newBalloon(location: CGPoint, pressState: UIGestureRecognizerState, immediate: Bool = false) {
        if pressState == UIGestureRecognizerState.Began || immediate == true {
            let balloonIdx = Int(arc4random_uniform(UInt32(self.balloonAssets.count)))
            let balloonAsset = self.balloonAssets[balloonIdx]
            let balloon = Balloon(imageNamed:balloonAsset)
            balloon.xScale = 0.15
            balloon.yScale = 0.15
            balloon.position = self.convertPointToView(location)
            balloon.inflate()
            if immediate == true {
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: balloon, selector: Selector("floatAway"), userInfo: nil, repeats: false)
            }
            self.addChild(balloon)
        }
        else if pressState == UIGestureRecognizerState.Ended {
            let arr = self.balloons()
            if arr.count > 0 {
                let balloon = arr[arr.count - 1]
                balloon.floatAway()
            }
        }

    }
}
