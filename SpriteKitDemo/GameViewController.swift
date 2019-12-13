//
//  GameViewController.swift
//  SpriteKitDemo
//
//  Created by xuss on 2019/12/13.
//  Copyright © 2019 XQD. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let scene = GameScene(size: view.bounds.size)  //通过代码创建一个GameScene类的实例对象
            
            scene.scaleMode = .aspectFill

            view.presentScene(scene)

            view.ignoresSiblingOrder = true

            view.showsFPS = true

            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
