import Foundation

class MainScene: CCNode, CCPhysicsCollisionDelegate
{
    weak var hero: CCSprite!
    weak var gamePhysicsNode: CCPhysicsNode!
    weak var ground1: CCSprite!
    weak var ground2: CCSprite!
    weak var obstaclesLayer: CCNode!
    weak var restartButton: CCButton!
    weak var scoreLabel: CCLabelTTF!
    var sinceTouch: CCTime = 0
    var scrollSpeed: CGFloat = 80
    var grounds = [CCSprite]() //array for the ground sprites
    var obstacles : [CCNode] = [] //array of obstacles
    let firstObstaclePosition : CGFloat = 280
    let distanceBetweenObstacles : CGFloat = 160
    var gameOver = false
    var points: NSInteger = 0
    

    func didLoadFromCCB() //what happens first, right when the app starts?
    {
        userInteractionEnabled = true
        //add the two grounds to the ground array
        grounds.append(ground1)
        grounds.append(ground2)
        
        //create three obstacles that will start off the infinite creation system
        spawnNewObstacle()
        spawnNewObstacle()
        spawnNewObstacle()
        
        //assigning MainScene as the collision delegate class
        gamePhysicsNode.collisionDelegate = self
    }
    
    override func touchBegan(touch: CCTouch!, withEvent event: CCTouchEvent)
    {
        if (gameOver == false)
        {
            hero.physicsBody.applyImpulse(ccp(0, 400))
            hero.physicsBody.applyAngularImpulse(10000)
            sinceTouch = 0
        }
    }
    
    override func update(delta: CCTime)
    {
        //limits velocity between -infinity and 200
        let velocityY = clampf(Float(hero.physicsBody.velocity.y), -Float(CGFloat.max), 200)
        //sets velocity back to the limited velocity
        hero.physicsBody.velocity = ccp(0,CGFloat(velocityY))
        
        //change in time
        sinceTouch += delta
        //limit position between 30 degrees up and 90 down
        hero.rotation = clampf(hero.rotation, -30, 90)
        if(hero.physicsBody.allowsRotation)
        {
            //limits angular velocity between -2 and 1
            let angularVelocity = clampf(Float(hero.physicsBody.angularVelocity), -2, 1)
            //set angular velocity back to angularVelocity
            hero.physicsBody.angularVelocity = CGFloat(angularVelocity)
        }
        if (sinceTouch > 0.3)
        {
            //applies the downwards impulse to the bunny after a time
            let impulse = -18000.0 * delta
            hero.physicsBody.applyAngularImpulse(CGFloat(impulse))
        }
        
        //moves hero to the right
        //multiplying by delta ensures that the hero moves at the same speed, no matter the frame rate
        hero.position = ccp(hero.position.x + scrollSpeed * CGFloat(delta), hero.position.y)
        //moves physics node (camera) to the left
        gamePhysicsNode.position = ccp(gamePhysicsNode.position.x - scrollSpeed * CGFloat(delta), gamePhysicsNode.position.y)
        //rounds the physics node to the nearest int to prevent black line artifact
        let scale = CCDirector.sharedDirector().contentScaleFactor
        gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x * scale) / scale, round(gamePhysicsNode.position.y * scale) / scale)
        hero.position = ccp(round(hero.position.x * scale) / scale, round(hero.position.y * scale) / scale)
        //easier way, but lesser quality
        //gamePhysicsNode.position = ccp(round(gamePhysicsNode.position.x), round(gamePhysicsNode.position.y))
        
        //loop ground whenever the ground image is moved completely off the stage
        //go through grounds array
        for ground in grounds
        {
            //get the position of the ground on the world, and then on the screen
            let groundWorldPosition = gamePhysicsNode.convertToWorldSpace(ground.position)
            let groundScreenPosition = convertToNodeSpace(groundWorldPosition)
            //if the x-position of the side of the ground is less than the width of the ground (if its off screen)
            if groundScreenPosition.x <= (-ground.contentSize.width)
            {
                //move the ground two ground-widths to the right
                ground.position = ccp(ground.position.x + ground.contentSize.width * 2, ground.position.y)
            }
        }
        
        for obstacle in obstacles
        {
            //getting obstacle position on screen
            let obstacleWorldPosition = gamePhysicsNode.convertToWorldSpace(obstacle.position)
            let obstacleScreenPosition = convertToNodeSpace(obstacleWorldPosition)
            
            // obstacle moved past left side of screen?
            if obstacleScreenPosition.x < (-obstacle.contentSize.width)
            {
                obstacle.removeFromParent()
                obstacles.removeAtIndex(find(obstacles, obstacle)!)
                
                // for each removed obstacle, add a new one
                spawnNewObstacle()
            }
        }
        
    }
    
    func spawnNewObstacle()
    {
        //first obstacle will be at firstObstaclePosition
        var prevObstaclePos = firstObstaclePosition
        //previous position set to position of the last one
        if obstacles.count > 0
        {
            prevObstaclePos = obstacles.last!.position.x
        }
        
        // create and add a new obstacle, cast as Obstacle
        let obstacle = CCBReader.load("Obstacle") as! Obstacle
        //set position of new obstacle
        obstacle.position = ccp(prevObstaclePos + distanceBetweenObstacles, 0)
        //call Obstacle method to randomize position
        obstacle.setupRandomPosition()
        //add new obstacle to the physics node
        obstaclesLayer.addChild(obstacle)
        //add new obstacle to the array of obstacles
        obstacles.append(obstacle)
    }
    
    //detects collisions between hero and level items, which were defined in SpriteBuilder
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, level: CCNode!) -> Bool
    {
        triggerGameOver()
        return true
    }
    
    //detects collisions between the hero and the goal
    func ccPhysicsCollisionBegin(pair: CCPhysicsCollisionPair!, hero: CCNode!, goal: CCNode!) -> Bool
    {
        //remove goal so no duplicate scoring
        goal.removeFromParent()
        points++
        //set the scorelabel to a string value of points
        scoreLabel.string = String(points)
        return true
    }
    
    //restarts game
    func restart()
    {
        let scene = CCBReader.loadAsScene("MainScene")
        CCDirector.sharedDirector().presentScene(scene)
    }
    
    //handles what happens when the game is over
    func triggerGameOver()
    {
        if (gameOver == false)
        {
            gameOver = true
            restartButton.visible = true
            scrollSpeed = 0
            hero.rotation = 90
            hero.physicsBody.allowsRotation = false
            
            // just in case
            hero.stopAllActions()
            
            //makes a sequence that shakes the screen up and down (switch to 4,0 for side to side
            let move = CCActionEaseBounceOut(action: CCActionMoveBy(duration: 0.2, position: ccp(0, 4)))
            let moveBack = CCActionEaseBounceOut(action: move.reverse())
            let shakeSequence = CCActionSequence(array: [move, moveBack])
            runAction(shakeSequence)
        }
    }
}
