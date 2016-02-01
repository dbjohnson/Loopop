//
//  GameScene.swift
//  Loopop
//
//  Created by Bryan Johnson on 1/30/16.
//  Copyright (c) 2016 Lucy Johnson. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    let poppers = ["Beak", "Carrot", "Knife", "Mountain", "Needle", "Pencil", "Scissors", "Sword"]
    let balloons = ["Heart", "Purple", "Pink", "Blue", "Green", "Yellow"]
    
    let pop = NSDataAsset(name: "Pop")!
    let blow = NSDataAsset(name: "Blow")!
    var player: AVAudioPlayer!
    var popper: SKSpriteNode!
    
    override func didMoveToView(view: SKView) {
        self.anchorPoint = CGPointMake(0, 0)
        let background = SKSpriteNode(imageNamed:"Background")
        background.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        background.size = self.frame.size;
        self.addChild(background)
        self.popper = self.addSprite("Pencil", name: "Popper", position: background.position)
        self.popper.zPosition = 1000
    }

    override func update(currentTime: CFTimeInterval) {
        for sprite: SKNode in self.children {
            if sprite.name == "Balloon" && sprite.containsPoint(self.popper.position) {
                self.pop(sprite)
            }
            else if !self.frame.intersects(sprite.frame) {
                sprite.removeFromParent()
            }
        }
    }

    func playSound(soundAsset: NSDataAsset) {
        do {
            player = try AVAudioPlayer(data: soundAsset.data)
            player.prepareToPlay()
            player.play()
        } catch {
            print("No sound found")
        }
    }
    
    func pop(sprite: SKNode) {
        sprite.removeFromParent()
        self.playSound(pop)
    }
    
    func movePopper(location: CGPoint) {
        let pos = self.convertPointToView(location)
        if hypot(pos.x - self.popper.position.x, pos.y - self.popper.position.y) < 0.1 * self.frame.width {
            self.popper.position = self.convertPointToView(location)
            for sprite: SKNode in self.children {
                if sprite.name == "Balloon" && sprite.containsPoint(self.popper.position) {
                    self.pop(sprite)
                }
            }
        }
    }

    func newBalloon(location: CGPoint) {
        self.playSound(blow)
        let position = self.convertPointToView(location)
        let ballonIdx = Int(arc4random_uniform(UInt32(balloons.count)))
        let sprite = self.addSprite(balloons[ballonIdx],
                                    name: "Balloon",
                                    position: position,
                                    scale: 0.1)

        let dx = CGFloat(arc4random_uniform(20))
        let dy = CGFloat(arc4random_uniform(50))
        let action = SKAction.moveBy(CGVectorMake(dx, dy), duration: 1)
        sprite.runAction(SKAction.repeatActionForever(action))
        let finalScale = 0.5 * CGFloat(arc4random_uniform(100)) / 100.0 + 0.25
        sprite.runAction(SKAction.scaleTo(finalScale, duration: 1))
        
    }

    func addSprite(imagename: String,
                   name: String,
                   position: CGPoint,
                   scale:CGFloat=0.15) -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed:imagename)
        sprite.name = name
        sprite.xScale = scale
        sprite.yScale = scale
        sprite.position = position
                
        self.addChild(sprite)
        return(sprite)
    }    
}
