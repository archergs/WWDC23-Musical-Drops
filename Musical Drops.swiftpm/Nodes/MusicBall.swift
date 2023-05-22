//
//  MusicBall.swift
//  Musical Drops
//
//  Created by Archer Gardiner-Sheridan on 7/4/2023.
//

import Foundation
import SpriteKit


class MusicBall : SKShapeNode {
    
    private var touchedLines : [MusicLine] = []
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(radius: CGFloat, note: MusicNote) {
        super.init()
        
        let circlePath = CGMutablePath()
        circlePath.addArc(center: CGPoint(x: 0, y: 0), radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        path = circlePath
        
        name = "ball"
        
        switch note {
        case .a:
            fillColor = .red
        case .b:
            fillColor = .orange
        case .c:
            fillColor = .blue
        case .d:
            fillColor = .green
        case .e:
            fillColor = .brown
        case .f:
            fillColor = .cyan
        case .g:
            fillColor = .purple
        }
        
        self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        
        self.physicsBody!.contactTestBitMask = self.physicsBody!.collisionBitMask
    }
    
    public func touchedNewLine(_ line: MusicLine) {
        if !touchedLines.contains(line){
            touchedLines.append(line)
        }
    }
    
    public func hasTouchedLine(_ line: MusicLine) -> Bool {
        return touchedLines.contains(line)
    }
}
