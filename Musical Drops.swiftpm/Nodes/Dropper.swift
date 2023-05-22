//
//  Dropper.swift
//  Musical Drops
//
//  Created by Archer Gardiner-Sheridan on 7/4/2023.
//

import Foundation
import SpriteKit

class Dropper : SKShapeNode {
    
    private var timer : Timer?
    private var gameScene : SKScene?
    
    public var beatTrigger : [Bool] = [true, false, false, false]
    
    init(interval: Double, parentScene: SKScene){
        gameScene = parentScene
        
        print(interval)
        
        super.init()
        
        // create dropper shape
        let rect = CGRect(x: -25, y: -10, width: 50, height: 15)
        let rectPath = CGPath(roundedRect: rect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        
        self.path = rectPath
        self.fillColor = .purple
        
        //spawnMusicBall()
        
        //setTimerInterval(newInterval: interval)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setTimerInterval(newInterval: Double){
        timer?.invalidate()
        
        /*self.timer = Timer.scheduledTimer(withTimeInterval: newInterval, repeats: true, block: { _ in
            self.spawnMusicBall()
        })*/
        self.timer = Timer(timeInterval: newInterval, target: self, selector: #selector(spawnMusicBall), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    public func terminateTimer(){
        timer?.invalidate()
    }
    
    @objc public func spawnMusicBall(){
        let musicBall = MusicBall(radius: 10, note: .c)
        musicBall.position = CGPoint(x: self.position.x, y: self.position.y - 5)
        
        // add to parent so existing balls dont delete if dropper is deleted
        self.parent?.addChild(musicBall)
    }
    
}
