//
//  GameScene.swift
//  Loopop
//
//  Created by Bryan Johnson on 1/30/16.
//  Copyright (c) 2016 Lucy Johnson. All rights reserved.
//

import SpriteKit
import AVFoundation
import GameplayKit


class SoundManager: NSObject {
    var player: AVAudioPlayer!
    
    init(soundAssetName: String, loop: Bool = false) {
        do {
            try self.player = AVAudioPlayer(data: NSDataAsset(name: soundAssetName)!.data)
            if loop {
                self.player.numberOfLoops = -1 // loop indefinitely
            }
        } catch {
            print("No sound found")
        }
        super.init()
    }
}


// global pop sound player so audio player doesn't go out of scope (and stop playing) as soon as we pop a balloon
let popPlayer = SoundManager(soundAssetName: "Pop")

// global wind -- affects the drift of all balloons
let gusts = GKGaussianDistribution(randomSource: GKRandomSource(), mean: 0, deviation: 10)
var wind = gusts.nextInt()

// global noise - add a bit of character to each balloon/s drift
let noise = GKGaussianDistribution(randomSource: GKRandomSource(), mean: 0, deviation: 3)


class Balloon: SKSpriteNode {
    var inflating = false
    let blowPlayer = SoundManager(soundAssetName: "Blow", loop: true)
    
    func inflate() {
        self.inflating = true
        self.blowPlayer.player.play()
        
        // try to make the inflation look ~natural, and match the length
        // of the breath sound
        let totalDuration = blowPlayer.player.duration
        let fast = SKAction.scaleBy(1.5, duration: totalDuration/3)
        let med = SKAction.scaleBy(1.3, duration: totalDuration/3)
        let slow = SKAction.scaleBy(1.02, duration: totalDuration/3)
        let sequence = SKAction.sequence([fast, med, slow])
        self.runAction(SKAction.repeatActionForever(sequence))
    }
    
    func tieOff() {
        self.inflating = false
        self.blowPlayer.player.stop()
        self.float()
    }
    
    func float(dx: Int = wind + noise.nextInt(),
               dy: Int = 30 + noise.nextInt()) {
        self.removeAllActions()
        let action = SKAction.moveBy(CGVectorMake(CGFloat(dx), CGFloat(dy)), duration: 1)
        self.runAction(SKAction.repeatActionForever(action))
    }
    
    func pop() {
        popPlayer.player.play()
        self.removeFromParent()
    }
    
}

class Cloud: SKSpriteNode {
    var age = 0
    
    func float(dx: Int = (wind + noise.nextInt()) / 2,
               frame: CGRect) {
            self.removeAllActions()
            let y = CGFloat(arc4random_uniform(UInt32(frame.height) / 2)) + frame.height / CGFloat(2.0)
            let x = dx > 0 ? 0 : frame.width
            if (dx > 0) {
                self.anchorPoint = CGPointMake(1, 1)
            }
            else {
                self.anchorPoint = CGPointMake(0, 1)
            }
                
            self.position = CGPointMake(x, y)
            let action = SKAction.moveBy(CGVectorMake(CGFloat(dx), 0.0), duration: 1)
            self.runAction(SKAction.repeatActionForever(action))
    }
}


class GameScene: SKScene {
    let popperAssets = ["Beak", "Carrot", "Knife", "Mountain", "Needle", "Pencil", "Scissors", "Sword"]
    let balloonAssets = ["Heart", "Purple", "Pink", "Blue", "Green", "Yellow"]
    let cloudAssets = ["cloud1", "cloud2", "cloud3", "cloud4"]

    var popper: SKSpriteNode!
    var sun: SKSpriteNode!
    
    override func didMoveToView(view: SKView) {
        let background = SKSpriteNode(imageNamed: "Background")
        background.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        background.size = self.frame.size
        self.addChild(background)
        
        self.popper = SKSpriteNode(imageNamed: "Pencil")
        self.popper.anchorPoint = CGPointMake(0.5, 1.0)
        self.popper.xScale = 0.15
        self.popper.yScale = 0.15
        self.popper.position = background.position
        self.popper.zPosition = 1000 // keep popper above all other sprites
        self.addChild(popper)
        
        self.sun = SKSpriteNode(imageNamed: "sun")
        self.sun.xScale = 0.5
        self.sun.yScale = 0.5
        self.sun.position = CGPointMake(self.frame.width * 0.1, self.frame.height * 0.9)
        self.sun.zPosition = 0 // keep sun below all other sprites
        let spin = SKAction.rotateByAngle(6.14, duration: 60)
        self.sun.runAction(SKAction.repeatActionForever(spin))
        self.addChild(sun)
        
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
        
        
        for cloud: Cloud in self.clouds() {
            cloud.age += 1
            if !self.frame.intersects(cloud.frame) && cloud.age > 10 {
                cloud.removeFromParent()
            }
            
        }
        
        // occasionally update the wind speed that controls the balloon drift
        if arc4random_uniform(100) > 95 {
            wind += gusts.nextInt()
            if abs(wind) > 40 {
                wind = 40 * Int(sign(Float(wind)))
            }
            for balloon: Balloon in self.balloons() {
                if balloon.inflating == false {
                    balloon.float()
                }
            }
        }
        
        // occasionally add a new cloud
        if arc4random_uniform(100) >= 99 && self.clouds().count < 5 {
            let idx = Int(arc4random_uniform(UInt32(self.cloudAssets.count)))
            let asset = self.cloudAssets[idx]
            let c = Cloud(imageNamed: asset)
            c.xScale = 0.25
            c.yScale = 0.25
            c.float(frame: frame)
            self.addChild(c)
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

    func clouds() -> Array<Cloud> {
        return self.children.flatMap{$0 as? Cloud}
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
            if immediate {
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: balloon, selector: Selector("tieOff"), userInfo: nil, repeats: false)
            }
            self.addChild(balloon)
        }
        else if pressState == UIGestureRecognizerState.Ended {
            let arr = self.balloons()
            if arr.count > 0 {
                let balloon = arr[arr.count - 1]
                balloon.tieOff()
            }
        }

    }
}
