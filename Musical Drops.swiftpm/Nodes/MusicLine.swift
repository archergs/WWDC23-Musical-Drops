//
//  MusicLine.swift
//  Musical Drops
//
//  Created by Archer Gardiner-Sheridan on 10/4/2023.
//

import Foundation
import SpriteKit

class MusicLine : SKShapeNode, ObservableObject {
    
    @Published var instrument : Instrument = .drum
    @Published var drumType : DrumType? = .kick
    @Published var note : MusicNote? = .c
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(linePath: CGPath){
        super.init()
        
        path = linePath
        
        if instrument == .drum {
            name = "line_" + (drumType?.rawValue ?? "")
        } else {
            name = "line_" + (instrument.rawValue) + (note?.rawValue ?? "")
        }
        
        userData = ["instrument":instrument, "drumType": drumType, "note":note]
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: linePath)
        
        self.physicsBody!.contactTestBitMask = self.physicsBody!.collisionBitMask
    }
}
