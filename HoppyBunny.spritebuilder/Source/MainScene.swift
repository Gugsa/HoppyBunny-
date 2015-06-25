
import Foundation

class MainScene: CCNode, CCPhysicsCollisionDelegate{
    
    weak var hero: CCSprite!  // makes connection with Sprite Builder
    weak var gamePhysicsNode : CCPhysicsNode!
    
    var sinceTouch : CCTime = 0 //  keeps track of the time since the last touch
    var scrollSpeed : CGFloat = 80
    
    weak var ground1 : CCSprite!
    weak var ground2 : CCSprite!
    var grounds = [CCSprite]()  // initializes an empty array
    
    var obstacles : [CCNode] = []
    let firstObstaclePosition : CGFloat = 280
    let distanceBetweenObstacles : CGFloat = 160
    
    weak var obstaclesLayer : CCNode!
    
    weak var restartButton : CCButton!
    var gameOver = false
    
    var points : NSInteger = 0
    weak var scoreLabel : CCLabelTTF!
    
    
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, level: CCNode!) -> Bool {
        triggerGameOver()
        return true
    }
    
    
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero nodeA: CCNode!, goal: CCNode!) -> Bool {
        goal.removeFromParent()
        points++
        scoreLabel.string = String(points)
        return true
    }
    
    func restart() {
        let scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().presentScene(scene)
    }
    
    func triggerGameOver() {
        if (gameOver == false) {
            gameOver = true
            restartButton.visible = true
            scrollSpeed = 0
            hero.rotation = 90
            hero.physicsBody.allowsRotation = false
            
            // just in case
            hero.stopAllActions()
            
            let move = CCActionEaseBounceOut(action: CCActionMoveBy(duration: 0.2, position: ccp(0, 4)))
            let moveBack = CCActionEaseBounceOut(action: move.reverse())
            let shakeSequence = CCActionSequence(array: [move, moveBack])
            runAction(shakeSequence)
        }
    }

    
    func didLoadFromCCB() {
        userInteractionEnabled = true  // enables touch events
        grounds.append(ground1)
        grounds.append(ground2)
        spawnNewObstacle()
        spawnNewObstacle()
        spawnNewObstacle()
        gamePhysicsNode.collisionDelegate = self
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent!) {
         if (gameOver == false) {
        
        // applies an impulse to the bunny every time a touch is 1st detected
        hero.physicsBody.applyImpulse(ccp(0, 400))
        
        //trigger the upward rotation on a touch & by applying an angular impulse to the physics body
        hero.physicsBody.applyAngularImpulse(10000)
        
        //reset the sinceTouch value every time a touch occurs
        sinceTouch = 0
        }
    }
    
    // This method creates a new obstacle by loading it from the Obstacle.ccb file and places it within the defined distance of the last existing obstacle.
    
    func spawnNewObstacle() {
        var prevObstaclePos = firstObstaclePosition
        if obstacles.count > 0 {
            prevObstaclePos = obstacles.last!.position.x
        }
        
        // create and add a new obstacle
        
        let obstacle = CCBReader.load("Obstacle") as! Obstacle   // replace this line
        obstacle.position = ccp(prevObstaclePos + distanceBetweenObstacles, 0)
        
        obstacle.setupRandomPosition()   // add this line
        obstaclesLayer.addChild(obstacle)   // replace this line
        obstacles.append(obstacle)
    }
    
    override func update(delta: CCTime) {
        let velocityY = clampf(Float(hero.physicsBody.velocity.y), -Float(CGFloat.max), 200)
        hero.physicsBody.velocity = ccp(0, CGFloat(velocityY))
        
        sinceTouch += delta          // caputres how much time has passed since the last touch
        hero.rotation = clampf(hero.rotation, -30, 90)      // limit the rotation of the bunny
        
        if (hero.physicsBody.allowsRotation) {
            let angularVelocity = clampf(Float(hero.physicsBody.angularVelocity), -2, 1)
            hero.physicsBody.angularVelocity = CGFloat(angularVelocity)
        }
        if (sinceTouch > 0.3) {
            let impulse = -18000.0 * delta
            hero.physicsBody.applyAngularImpulse(CGFloat(impulse))
        }
        
        hero.position = ccp(hero.position.x + scrollSpeed * CGFloat(delta), hero.position.y)
        gamePhysicsNode.position = ccp(gamePhysicsNode.position.x - scrollSpeed * CGFloat(delta), gamePhysicsNode.position.y)
        
        let scale = CCDirector.sharedDirector().contentScaleFactor
        gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x * scale) / scale, round(gamePhysicsNode.position.y * scale) / scale)
        hero.position = ccp(round(hero.position.x * scale) / scale, round(hero.position.y * scale) / scale)
        
        // loop the ground whenever a ground image was moved entirely outside the screen
        for ground in grounds {
            let groundWorldPosition = gamePhysicsNode.convertToWorldSpace(ground.position)
            let groundScreenPosition = convertToNodeSpace(groundWorldPosition)
        
            if groundScreenPosition.x <= (-ground.contentSize.width) {
                ground.position = ccp(ground.position.x + ground.contentSize.width * 2, ground.position.y)
            }
        }
        
        for obstacle in obstacles.reverse() {
            let obstacleWorldPosition = gamePhysicsNode.convertToWorldSpace(obstacle.position)
            let obstacleScreenPosition = convertToNodeSpace(obstacleWorldPosition)
            
            // obstacle moved past left side of screen?
            if obstacleScreenPosition.x < (-obstacle.contentSize.width) {
                obstacle.removeFromParent()
                obstacles.removeAtIndex(find(obstacles, obstacle)!)
                
                // for each removed obstacle, add a new one
                spawnNewObstacle()
            }
        }
    }
    
}


