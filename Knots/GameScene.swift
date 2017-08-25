//
//  GameScene.swift
//  Knots
//
//  Created by Martin Tsang on 2017-08-21.
//  Copyright © 2017 Martin Tsang. All rights reserved.
//

import SpriteKit


class GameScene: SKScene, SKPhysicsContactDelegate {
    //Static Variables
    let rock = SKTexture(imageNamed: "cornerClouds")
    let DegreesToRadians = CGFloat.pi / 180
    var light = SKSpriteNode()
    var lightHouse = SKSpriteNode()
    var scoreLabel = SKLabelNode()
    let userDefaults = UserDefaults.standard
    
    
    
    //Tunable Variables
    let lightHouseRotationTimeTaken:Double = 0.5
    var powerUp:Bool = false
    
    //Counters
    var nextRound:Int = 1
        //Scores
    var highScore:Int = 0
    var currentScore:Int = 0
    var powerUpScore:Int = 0

    
    struct PhysicsCategories {
        static let None : UInt32 = 0x1 << 0
        static let Frame :UInt32 = 0x1 << 1
        static let Boat : UInt32 = 0x1 << 2
        static let Light : UInt32 = 0x1 << 3
        static let LightHouse : UInt32 = 0x1 << 4
    }
    
    
    override func didMove(to view: SKView) {
        //Setup Physics in this world + remove gravity from the world
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector.zero

        //Setup Corner rocks
        setupSceneCornerRocks()
        
        //Setup Lighthouse Collision
        self.lightHouse = self.childNode(withName:"LightHouse") as! SKSpriteNode
        self.lightHouse.physicsBody!.categoryBitMask = PhysicsCategories.LightHouse
        self.lightHouse.physicsBody!.collisionBitMask = PhysicsCategories.Boat
        self.lightHouse.physicsBody!.contactTestBitMask = PhysicsCategories.Boat
        
        //Setup cone of light
        setupConeOfLightProperty()
        
        //Setup Scene Physics
        physicsBody = SKPhysicsBody(rectangleOf: self.size)
        physicsBody!.categoryBitMask = PhysicsCategories.Frame
        physicsBody!.collisionBitMask = PhysicsCategories.None
        physicsBody!.contactTestBitMask = PhysicsCategories.Boat
        
        //Setup High score
        if userDefaults.value(forKey: "highScore") != nil{
            highScore = userDefaults.value(forKey: "highScore") as! Int
        } else {
            userDefaults.set(0, forKey: "highScore")
            highScore = 0
        }
        
        //Setup Score Label
        scoreLabel = SKLabelNode(fontNamed: "AmericanTypewriter")
        scoreLabel.text = scoreOnLabel()
        scoreLabel.fontSize = 25
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: frame.midX, y: 3*frame.height/10)
        
        addChild(scoreLabel)
        
        //Start up spawn
        spawnController()
        
        //SFX Music Setup
        run(SKAction.playSoundFileNamed("GameSceneSFX.wav",waitForCompletion: true))
        
        //Random bird spawn
        spawnBirdManager()

    }
    
    func setupConeOfLightProperty() {
        //Set up cone of light Collision
        self.light = self.lightHouse.childNode(withName: "ConeOfLight") as! SKSpriteNode
        self.light.physicsBody!.categoryBitMask = PhysicsCategories.Light
        self.light.physicsBody!.collisionBitMask = PhysicsCategories.None
        self.light.physicsBody!.contactTestBitMask = PhysicsCategories.Boat
    }
    
    //Set up Rocks on the corner of the screens
    func setupSceneCornerRocks() {
        //Set the x+y coordinate
        //Top Left
        var xCoordinate:CGFloat = -(self.size.width/2)+(rock.size().width/13)
        var yCoordinate:CGFloat = (self.size.height/2)-(rock.size().height/15)
        
        var node = SKSpriteNode(texture: rock)
        node.position = CGPoint(x: xCoordinate, y:yCoordinate)
        node.size = CGSize(width: 150, height: 150)
        node.zRotation = CGFloat.pi
        node.xScale = node.xScale * -1;
        node.zPosition = 5
        node.run(animation())
        addChild(node)
        
        //Top Right
        xCoordinate = (self.size.width/2)-(rock.size().width/13)
        yCoordinate = (self.size.height/2)-(rock.size().height/15)
        
        node = SKSpriteNode(texture: rock)
        node.position = CGPoint(x: xCoordinate, y:yCoordinate)
        node.size = CGSize(width: 150, height: 150)
        node.zRotation = CGFloat.pi
        node.zPosition = 5
        node.run(animation())
        addChild(node)
        
        //Bottom left
        xCoordinate = -(self.size.width/2)+(rock.size().width/13)
        yCoordinate = -(self.size.height/2)+(rock.size().height/15)
        
        node = SKSpriteNode(texture: rock)
        node.position = CGPoint(x: xCoordinate, y:yCoordinate)
        node.size = CGSize(width: 150, height: 150)
        node.zPosition = 5
        node.run(animation())
        addChild(node)
        
        //Bottom Right
        xCoordinate = (self.size.width/2)-(rock.size().width/13)
        yCoordinate = -(self.size.height/2)+(rock.size().height/15)
        
        node = SKSpriteNode(texture: rock)
        node.position = CGPoint(x: xCoordinate, y:yCoordinate)
        node.size = CGSize(width: 150 , height: 150)
        node.xScale = node.xScale * -1;
        node.zPosition = 5
        node.run(animation())
        addChild(node)

    }
    
    func animation() -> SKAction {
        let negativeX:CGFloat = arc4random()%2==0 ? 5 : -5
        let negativeY:CGFloat = arc4random()%2==0 ? 5 : -5
        
        let up = SKAction.moveBy(x: negativeX, y: negativeY, duration: 1)
        let down = SKAction.moveBy(x:-negativeX, y:-negativeY, duration: 1)
        let sequence = SKAction.sequence([up,down])
        
        return SKAction.repeatForever(sequence)
    }
    
    
    /*
     
     
     Handling All Collision
     
     
     */
    
    //Called when 2 physics bodies (Nodes) make contact
    func didBegin(_ contact: SKPhysicsContact) {
        //Setup and assign bodies
        //Body 1 will always be the lower physics category
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        } else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        //Boat Vs Light
        if body1.categoryBitMask == PhysicsCategories.Boat &&
            body2.categoryBitMask == PhysicsCategories.Light {
            
            //if light hits boat
            let node = body1.node as! Boat
            if (!node.isLit && node.intersects(self.light)) {
                node.startTimerDown()
                node.isLit = true
            }
        }
        
        //Boat VS LightHouse
        if body1.categoryBitMask == PhysicsCategories.Boat &&
            body2.categoryBitMask == PhysicsCategories.LightHouse {
            
            //Music
            self.run(SKAction.playSoundFileNamed("lose.wav",waitForCompletion:false))
            
            //When a boat hits the Lighthouse
            userDefHighScoreUpdate ()
            self.pauseGame(paused: false)
            
        }
    }


    func didEnd(_ contact: SKPhysicsContact) {
        //Setup and assign bodies
        //Body 1 will always be the lower physics category
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        } else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        //Boat VS light
        if body1.categoryBitMask == PhysicsCategories.Boat &&
            body2.categoryBitMask == PhysicsCategories.Light {
            
            //light hits boat
            
            let node = body1.node as! Boat
            
            if (node.isLit) {
                print("Light Left boat")
                node.startTimerRegen()
                node.isLit = false
            }
        }
    }
    
    /*
     
     Score Manager
     
     */
    
    //Update user Default highscore
    func userDefHighScoreUpdate () {
        //Check if High score is the higher than what's stored in userDefaults
        if let currentHighScore = userDefaults.value(forKey: "highScore") as? Int {
            if self.highScore > currentHighScore {
                userDefaults.set(self.highScore, forKey: "highScore")
            }
        }
    }
    
    //updates the score and high score
    public func updateScoreBoatSaved() {
        self.currentScore += 1
        
        //Only add to power Up score if player doesn't have power up
        if (!self.powerUp) {
            self.powerUpScore += 1
        }
        if self.currentScore > self.highScore {
            self.highScore = self.currentScore
        }
        scoreLabel.text = scoreOnLabel()
    }
    
    func scoreOnLabel() ->String {
        return "Score: \(currentScore)    HighScore: \(highScore)"
    }
    
    /*
     
     Pause and Play game state
     
     
     */
    
    func pauseGame(paused: Bool) {
        self.scene?.isPaused = true
        for object in self.children {
            if let boat = object as? Boat {
                boat.timer.invalidate()
            }
        }
        
        //Adding Restart Button
        var node:SKSpriteNode = SKSpriteNode(texture: SKTexture(imageNamed: "restart"))
        node.position = CGPoint(x: self.frame.midX, y:self.frame.midY-80)
        node.size = CGSize(width: 100, height: 100)
        node.zPosition = 1000
        node.name = "restart"
        addChild(node)
        
        //Added Play Button
        if (paused) {
            node = SKSpriteNode(texture: SKTexture(imageNamed: "playButtonWhite"))
            node.position = CGPoint(x: self.frame.midX, y:self.frame.midY+80)
            node.size = CGSize(width: 100, height: 100)
            node.zPosition = 1000
            node.name = "play"
            addChild(node)
        } else {
            node.position = CGPoint(x: self.frame.midX, y:self.frame.midY)
        }
    }
    
    func resumeGame() {
        self.isPaused = false
        let play:SKNode = childNode(withName: "play")!
        let restart:SKNode = childNode(withName: "restart")!
        removeChildren(in: [play,restart])
    }
    
    func restartGame() {
        for object in self.children {
            if let boat = object as? Boat {
                self.removeChildren(in: [boat])
            }
        }
        
        //Remove buttons
        if let play = childNode(withName: "play") {
            removeChildren(in: [play])
        }
        
        if let restart = childNode(withName: "restart") {
            removeChildren(in: [restart])
        }
        
        //Reset all properties
        self.removeAllActions()
        self.currentScore = 0
        self.nextRound = 1
        scoreLabel.text = scoreOnLabel()
        self.isPaused = false
        spawnController()
        self.powerUpScore = 0
        self.powerUp = false
        self.childNode(withName: "FlashingLight")?.removeFromParent()
        
        //Reset bird spawn actions
        spawnBirdManager()
        
    }
    
    
    
    
    /*
     
     
     Handling Light + Light house control
     
     
     */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let curTouch = touches.first!
        let curPoint = curTouch.location(in: self)
        
        rotateLight(currentPoint: curPoint)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        let curTouch = touches.first!
        let curPoint = curTouch.location(in: self)
        
        //Checking For Pause Button
        let objectTouched:[SKNode] = nodes(at: curPoint)
        for object in objectTouched {
            if (object.name == "pause") {
                if (!isPaused) {
                    pauseGame(paused:true)
                }
            }
            if (object.name == "play") {
                resumeGame()
            }
            if (object.name == "restart"){
                object.removeFromParent()
                restartGame()
            }
            //Should be able to check only the parent without the child
            if (curPoint.x < self.lightHouse.size.width/2 &&
                curPoint.x > -self.lightHouse.size.width/2 &&
                curPoint.y < self.lightHouse.size.height/2 &&
                curPoint.y > -self.lightHouse.size.height/2) {
                pressedPowerUp()
                
            }
        }
        if (!self.isPaused){
            rotateLight(currentPoint: curPoint)
        }
    }
    
    func rotateLight (currentPoint:CGPoint ) {
        
        let deltaX = -currentPoint.x
        let deltaY = -currentPoint.y
        
        let angle = atan2(deltaY,deltaX) + 270 * DegreesToRadians
        
        let rotate = SKAction.rotate(toAngle: angle, duration:lightHouseRotationTimeTaken, shortestUnitArc: true)
        self.lightHouse.run(rotate)
        
        if let powerUpNode = self.childNode(withName: "FlashingLight") {
            powerUpNode.run(rotate)
        }
    }
    
    
    /*
     
     
     Spawn Mechanics
     
     
     */
    
    //Called Each one a new round happens
    func spawnController () {
        let waitTimeInbetween:Double = Double(arc4random_uniform(3)+3)
        var arrayOfActions:[SKAction] = []
            
        for _ in 1...4 {
            //Spawn the boat
            //Spawn 4xround number of boats
            for _ in 1...nextRound {
                let spawn = SKAction.run {
                    self.createBoat()
                }
                arrayOfActions.append(spawn)
                
                if (arc4random_uniform(2) == 0) {
                    //Wait time between all boats
                    let waitToSpawn = SKAction.wait(forDuration: waitTimeInbetween)
                    arrayOfActions.append(waitToSpawn)
                }
            }
                
            //Whether or not there's wait time between spawning more boats
            if (arc4random_uniform(2) == 0) {
                //Wait time between all boats
                let waitToSpawn = SKAction.wait(forDuration: waitTimeInbetween)
                arrayOfActions.append(waitToSpawn)
            }
        }
        let spawnSequence = SKAction.sequence(arrayOfActions)
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever, withKey:"BoatSpawn")
    }
    /*
 
 
     Power up
 
 
    */
    
    func screenFlashFromPowerUp() {
        //Music
        self.run(SKAction.playSoundFileNamed("horn.wav",waitForCompletion:false))
        
        //Flash
        let node = SKSpriteNode()
        node.color = UIColor.white
        node.size = frame.size
        node.zPosition = 2000
        node.position = CGPoint(x:0, y:0)
        addChild(node)
        
        
        let transition = SKAction.fadeOut(withDuration: 1)
        let fadeOut = SKAction.run {
            node.removeFromParent()
        }
        
        
        node.run(SKAction.sequence([transition,fadeOut]))
        
        //remove Flashing Node
        self.childNode(withName: "FlashingLight")?.removeFromParent()
    }
   
    
    
    func pressedPowerUp() {
        
        if (self.powerUp) {
            for object in self.children {
                if let boat = object as? Boat {
                    boat.saveBoat(powerUp: true)
                }
            }
            self.powerUp = false
            screenFlashFromPowerUp()
            self.powerUpScore = 0
        }
    }
    
    
    
    /*
 
 
     Creating a new Nodes
 
 
    */
    
    func spawnBirdManager() {
        
        var birdSpawns:[SKAction] = []
        
        let count = arc4random_uniform(3)+3
        let birdsAnimation = SKAction.run {
                self.createBird()
        }
        
        let wait =  SKAction.wait(forDuration: 30)
        
        for _ in 1...count {
            birdSpawns.append(birdsAnimation)
            birdSpawns.append(SKAction.wait(forDuration: 1))
        }
        birdSpawns.append(wait)
        //Music
        birdSpawns.append(SKAction.playSoundFileNamed("SFXSeagulls.wav",waitForCompletion:false))
        let sequence = SKAction.sequence(birdSpawns)
        self.run(SKAction.repeatForever(sequence))
        
      
    }
    
    func createBird() {
        let bird:Bird = Bird()
        self.addChild(bird)
        bird.move()
    }
    
    func createBoat() {
        var boatSize:Boat.BoatSizes = Boat.BoatSizes.big
        switch arc4random_uniform(3) {
        case 0:
            boatSize = Boat.BoatSizes.small
            break
        case 1:
            boatSize = Boat.BoatSizes.mid
            break;
        case 2:
            boatSize = Boat.BoatSizes.big
            break;
        default:
            boatSize = Boat.BoatSizes.small
        }
        //Create Boat
        let node = Boat.init(withSize: boatSize, gameScene: self)
        
        //Add movement
        node.run(SKAction.move(to: CGPoint(x:0,y:0), duration: node.boatSpeed), withKey: "movement")
        
        //Add Physics
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody!.affectedByGravity = false
        node.physicsBody!.categoryBitMask = PhysicsCategories.Boat
        node.physicsBody!.collisionBitMask = PhysicsCategories.LightHouse
        node.physicsBody!.contactTestBitMask = PhysicsCategories.Light | PhysicsCategories.Frame
        
        addChild(node)
    
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        
        if (self.currentScore/10 == nextRound) {
            removeAction(forKey: "BoatSpawn")
            nextRound += 1
            spawnController()
        }
        

        
        if (self.powerUpScore >= 5) {

            let node = SKSpriteNode()
            node.position = self.lightHouse.position
            node.size = CGSize(width: 80, height: 80)
            node.zPosition = 3000
            //node.color = UIColor.yellow
            node.name = "FlashingLight"
            node.zRotation = self.lightHouse.zRotation
            node.texture = SKTexture (imageNamed: "yellowLightHouse")
            node.anchorPoint = CGPoint(x: 0.5, y: 0.6)
            addChild(node)
            
            let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 0.2)
            let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.2)
            let fadeSequence = SKAction.sequence([fadeOut,fadeIn])
            node.run(SKAction.repeatForever(fadeSequence))
            
            self.powerUpScore = 0
            self.powerUp = true

        }
    }
}


