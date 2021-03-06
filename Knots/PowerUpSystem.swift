//
//  PowerUpSystem.swift
//  Knots
//
//  Created by Martin Tsang on 2017-08-26.
//  Copyright © 2017 Martin Tsang. All rights reserved.
//

import Foundation
import SpriteKit

class PowerUpSystem: SKNode{
    var gmScene:GameScene!
    /*
     
     
     Power up
     
     
     */
    
    func screenFlashFromPowerUp() {
        //Music
        gmScene?.run(SKAction.playSoundFileNamed("horn.wav",waitForCompletion:true))
        
        //Flash
        let node = SKSpriteNode()
        node.color = UIColor.white
        node.size = self.gmScene.frame.size
        node.zPosition = 2000
        node.position = CGPoint(x:0, y:0)
        self.gmScene.addChild(node)
        
        
        let transition = SKAction.fadeOut(withDuration: 1)
        let fadeOut = SKAction.run {
            node.removeFromParent()
        }
        
        
        node.run(SKAction.sequence([transition,fadeOut]))
        
        //remove Flashing Node
        self.gmScene.childNode(withName: "FlashingLight")?.removeFromParent()
    }
    
    
    
    func pressedPowerUp() {
        
        if self.gmScene.powerUp {
            for object in self.gmScene.children {
                if let boat = object as? Boat {
                    boat.saveBoat(powerUp: true)
                }
            }
            self.gmScene.powerUp = false
            screenFlashFromPowerUp()
            self.gmScene.scoringManager.powerUpScore = 0
        }
    }
    

}
