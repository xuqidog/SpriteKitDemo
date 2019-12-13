//
//  GameScene.swift
//  SpriteKitDemo
//
//  Created by xuss on 2019/12/13.
//  Copyright © 2019 XQD. All rights reserved.
//

import SpriteKit
import GameplayKit


let birdCategory: UInt32 = 0x1 << 0
let pipeCategory: UInt32 = 0x1 << 1
let floorCategory: UInt32 = 0x1 << 2


enum GameStatus {
    case idle //初始化
    case running //游戏运行中
    case over //游戏结束
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    var floor1: SKSpriteNode!
    var floor2: SKSpriteNode!
    var bird: SKSpriteNode!
    var meters = 0 {
        didSet  {
             metersLabel.text = "meters:\(meters)"
        }
    }
    
    
    var gameStatus: GameStatus = .idle //表示当前游戏状态的变量，初始值为初始化状态
    
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)  //给场景添加一个物理体，这个物理体就是一条沿着场景四周的边，限制了游戏范围，其他物理体就不会跑出这个场景
        self.physicsWorld.contactDelegate = self //物理世界的碰撞检测代理为场景自己，这样如果这个物理世界里面有两个可以碰撞接触的物理体碰到一起了就会通知他的代理
        
        floor1 = SKSpriteNode(imageNamed: "floor")
        floor1.anchorPoint = CGPoint(x: 0, y: 0)
        floor1.position = CGPoint(x: 0, y: 0)
        //配置地面1的物理体
        floor1.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor1.size.width, height: floor1.size.height))
        floor1.physicsBody?.categoryBitMask = floorCategory
        addChild(floor1)
        
        floor2 = SKSpriteNode(imageNamed: "floor")
        floor2.anchorPoint = CGPoint(x: 0, y: 0)
        floor2.position = CGPoint(x: floor1.size.width, y: 0)
        //配置地面2的物理体
        floor2.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: floor2.size.width, height: floor2.size.height))
        floor2.physicsBody?.categoryBitMask = floorCategory
        addChild(floor2)

        bird = SKSpriteNode(imageNamed: "player1")
        bird.size = CGSize(width: 50, height: 43);
        //配置鸟的物理体
        bird.physicsBody = SKPhysicsBody(texture: bird.texture!, size: bird.size)
        bird.physicsBody?.allowsRotation = false  //禁止旋转
        bird.physicsBody?.categoryBitMask = birdCategory //设置小鸟物理体标示
        bird.physicsBody?.contactTestBitMask = floorCategory | pipeCategory  //设置可以小鸟碰撞检测的物理体
        addChild(bird)
        
        // Set Meter Label
        metersLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
        metersLabel.zPosition = 100
        addChild(metersLabel)
        
        shuffle()
    }
    override func update(_ currentTime: TimeInterval) {
        if gameStatus != .over {
            moveScene()
        }
        if gameStatus == .running {
              meters += 1
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameStatus {
            case .idle:
                startGame() //如果在初始化状态下，玩家点击屏幕则开始游戏
            case .running:
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 40))
            case .over:
                shuffle() //如果在游戏结束状态下，玩家点击屏幕则进入初始化状态
            }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
            //先检查游戏状态是否在运行中，如果不在运行中则不做操作，直接return
            if gameStatus != .running { return }
        //为了方便我们判断碰撞的bodyA和bodyB的categoryBitMask哪个小，小的则将它保存到新建的变量bodyA里的，大的则保存到新建变量bodyB里
            var bodyA : SKPhysicsBody
            var bodyB : SKPhysicsBody
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                bodyA = contact.bodyA
                bodyB = contact.bodyB
           }else {
                bodyA = contact.bodyB
                bodyB = contact.bodyA
           }
           //接下来判断bodyA是否为小鸟，bodyB是否为水管或者地面，如果是则游戏结束，直接调用gameOver()方法
           if (bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == pipeCategory) ||
               (bodyA.categoryBitMask == birdCategory && bodyB.categoryBitMask == floorCategory) {
                   gameOver()
           }
    }

    //游戏初始化处理方法
    func shuffle()  {
        gameStatus = .idle
        removeAllPipesNode()
        gameOverLabel.removeFromParent()
        bird.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        bird.physicsBody?.isDynamic = false
        meters = 0
        birdStartFly()
    }
    
    //游戏开始处理方法
    func startGame()  {
        gameStatus = .running
        bird.physicsBody?.isDynamic = true
        startCreateRandomPipesAction()  //开始循环创建随机水管
    }
    
    //游戏结束处理方法
    func gameOver()  {
        gameStatus = .over
        birdStopFly()
        stopCreateRandomPipesAction()
        
        //禁止用户点击屏幕
        isUserInteractionEnabled = false
        //添加gameOverLabel到场景里
        addChild(gameOverLabel)
        //设置gameOverLabel其实位置在屏幕顶部
        gameOverLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
        //让gameOverLabel通过一个动画action移动到屏幕中间
        gameOverLabel.run(SKAction.move(by: CGVector(dx:0, dy:-self.size.height * 0.5), duration: 0.5), completion: {
                //动画结束才重新允许用户点击屏幕
            self.isUserInteractionEnabled = true
        })
    }
    
    //开始飞
    func birdStartFly() {
        let flyAction = SKAction.animate(with: [SKTexture(imageNamed: "player1"),
                                                SKTexture(imageNamed: "player2"),
                                                SKTexture(imageNamed: "player3"),
                                                SKTexture(imageNamed: "player2")],
                                         timePerFrame: 0.15)
        bird.run(SKAction.repeatForever(flyAction), withKey: "fly")
    }
     
    //停止飞
    func birdStopFly() {
        bird.removeAction(forKey: "fly")
    }
    
    //场景移动
    func moveScene() {
        floor1.position = CGPoint(x: floor1.position.x - 1, y: floor1.position.y)
        floor2.position = CGPoint(x: floor2.position.x - 1, y: floor2.position.y)
        
        if floor1.position.x < -floor1.size.width {
            floor1.position = CGPoint(x: floor2.position.x + floor2.size.width, y: floor1.position.y)
        }
        if floor2.position.x < -floor2.size.width {
               floor2.position = CGPoint(x: floor1.position.x + floor1.size.width, y: floor2.position.y)
        }
        
        //循环检查场景的子节点，同时这个子节点的名字要为pipe
        for pipeNode in self.children where pipeNode.name == "pipe" {
            //因为我们要用到水管的size，但是SKNode没有size属性，所以我们要把它转成SKSpriteNode
            if let pipeSprite = pipeNode as? SKSpriteNode {
                    //将水管左移1
                    pipeSprite.position = CGPoint(x: pipeSprite.position.x - 1, y: pipeSprite.position.y)
                    //检查水管是否完全超出屏幕左侧了，如果是则将它从场景里移除掉
                    if pipeSprite.position.x < -pipeSprite.size.width * 0.5 {
                          pipeSprite.removeFromParent()
                   }
            }
        }
    }
    
    //创建上水管
    func addPipes(topSize: CGSize, bottomSize: CGSize) {
        let topTexture = SKTexture(imageNamed: "topPipe")      //利用上水管图片创建一个上水管纹理对象
        let topPipe = SKSpriteNode(texture: topTexture, size: topSize)  //利用上水管纹理对象和传入的上水管大小参数创建一个上水管对象
        topPipe.name = "pipe"   //给这个水管取个名字叫pipe
        topPipe.position = CGPoint(x: self.size.width + topPipe.size.width * 0.5, y: self.size.height - topPipe.size.height * 0.5) //设置上水管的垂直位置为顶部贴着屏幕顶部，水平位置在屏幕右侧之外
        
        //创建下水管，每一句方法都与上面创建上水管的相同意义
        let bottomTexture = SKTexture(imageNamed: "bottomPipe")
        let bottomPipe = SKSpriteNode(texture: bottomTexture, size: bottomSize)
        bottomPipe.name = "pipe"
        bottomPipe.position = CGPoint(x: self.size.width + bottomPipe.size.width * 0.5, y: floor1.size.height + bottomPipe.size.height * 0.5)  //设置下水管的垂直位置为底部贴着地面的顶部，水平位置在屏幕右侧之外
        
        //配置上水管物理体
        topPipe.physicsBody = SKPhysicsBody(texture: topTexture, size: topSize)
        topPipe.physicsBody?.isDynamic = false
        topPipe.physicsBody?.categoryBitMask = pipeCategory
        //配置下水管物理体
        bottomPipe.physicsBody = SKPhysicsBody(texture: bottomTexture, size: bottomSize)
        bottomPipe.physicsBody?.isDynamic = false
        bottomPipe.physicsBody?.categoryBitMask = pipeCategory

        //将上下水管添加到场景里
        addChild(topPipe)
        addChild(bottomPipe)
    }
    
    func createRandomPipes() {
 
        //先计算地板顶部到屏幕顶部的总可用高度
        let height = self.size.height - self.floor1.size.height //计算上下管道中间的空档的随机高度，最小为空档高度为2.5倍的小鸟的高度，最大高度为3.5倍的小鸟高度
        let pipeGap = CGFloat(arc4random_uniform(UInt32(bird.size.height))) + bird.size.height * 2.5
        //管道宽度在60
        let pipeWidth = CGFloat(60.0)
        //随机计算顶部pipe的随机高度，这个高度肯定要小于(总的可用高度减去空档的高度)
        let topPipeHeight = CGFloat(arc4random_uniform(UInt32(height - pipeGap)))
         //总可用高度减去空档gap高度减去顶部水管topPipe高度剩下就为底部的bottomPipe高度
        let bottomPipeHeight = height - pipeGap - topPipeHeight
        //调用添加水管到场景方法
        addPipes(topSize: CGSize(width: pipeWidth, height: topPipeHeight), bottomSize: CGSize(width: pipeWidth, height: bottomPipeHeight))
    }
    
    func startCreateRandomPipesAction() {
        //创建一个等待的action,等待时间的平均值为3.5秒，变化范围为1秒
        let waitAct = SKAction.wait(forDuration: 3.5, withRange: 1.0)
    //创建一个产生随机水管的action，这个action实际上就是调用一下我们上面新添加的那个createRandomPipes()方法
        let generatePipeAct = SKAction.run {
                self.createRandomPipes()
        }
        //让场景开始重复循环执行"等待" -> "创建" -> "等待" -> "创建"。。。。。
        //并且给这个循环的动作设置了一个叫做"createPipe"的key来标识它
        run(SKAction.repeatForever(SKAction.sequence([waitAct, generatePipeAct])), withKey: "createPipe")
    }
    
    //停止创建水管
    func stopCreateRandomPipesAction() {
        self.removeAction(forKey: "createPipe")
    }
    
    //移除掉场景里的所有水管
    func removeAllPipesNode() {
        for pipe in self.children where pipe.name == "pipe" {  //循环检查场景的子节点，同时这个子节点的名字要为pipe
                pipe.removeFromParent()  //将水管这个节点从场景里移除掉
        }
    }
    
    lazy var gameOverLabel: SKLabelNode = {
             let label = SKLabelNode(fontNamed: "Chalkduster")
             label.text = "Game Over"
             return label
    }()
    
    lazy var metersLabel: SKLabelNode = {
            let label = SKLabelNode(text: "meters:0")
            label.verticalAlignmentMode = .top
            label.horizontalAlignmentMode = .center
            return label
    }()
}
