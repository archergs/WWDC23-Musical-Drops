import SwiftUI
import SpriteKit

class GameScene : SKScene, SKPhysicsContactDelegate, ObservableObject {
    
    private var currentLine : [CGPoint] = []
    private var currentMode : GameMode = .drawLines
    private var currentBPM : Int = 120
    
    private var activeDroppers : [Dropper] = []
    private var existingLines : [MusicLine] = []
    
    private var soundActions : [String:SKAction] = [:]
    
    private var dropperTrigger: Timer?
    private var beatCount : Int = 0 // 1-4, keeps track of which beat we are on in a bar
    
    @Published var selectedLineNode : MusicLine?
    @Published var selectedDropper : Dropper?
    
    override func didMove(to view: SKView) {
        //physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self
        
        // load all the instrument sounds
        loadInstrumentSounds()
        
        gameTimer()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // remove balls that are off-screen
        for dropper in activeDroppers {
            for musicBall in dropper.children {
                if !intersects(musicBall){
                    musicBall.removeFromParent()
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        print(currentMode)
        
        switch currentMode {
        case .drawLines: // spawn a new music line
            if currentLine.count >= 1 { // this is the last point for a line
                currentLine.append(location)
                
                let path = CGMutablePath()
                path.move(to: currentLine[0])
                path.addLine(to: currentLine[1])
                
                let line = MusicLine(linePath: path)
                line.strokeColor = .black
                line.lineWidth = 4
                
                addChild(line)
                
                existingLines.append(line)
                
                selectedLineNode = line
                selectedLineNode?.strokeColor = .orange
                
                currentLine = [] // empty for next line
            } else {
                // reset color to default and deselect
                selectedLineNode?.strokeColor = .black
                selectedLineNode = nil
                currentLine.append(location)
            }
        case .createDropper: // spawn a new music circle
            let interval = 60.0 / Double(currentBPM)
            let dropper = Dropper(interval: interval, parentScene: self)
            dropper.position = location
            addChild(dropper)
            
            activeDroppers.append(dropper)
        case .edit:
            // reset color to default
            selectedLineNode?.strokeColor = .black
            selectedDropper?.strokeColor = .purple
            // deselect by default, assuming the user hasnt touched a node
            selectedLineNode = nil
            selectedDropper = nil
            
            for node in nodes(at: location){
                if let line = node as? MusicLine {
                    print("touched a line")
                    // deselect any droppers
                    selectedDropper?.strokeColor = .purple
                    selectedDropper = nil
                    
                    selectedLineNode = line
                    selectedLineNode?.strokeColor = .orange
                    break
                } else if let dropper = node as? Dropper {
                    print("touched a dropper")
                    // deselect any lines
                    selectedLineNode?.strokeColor = .black
                    selectedLineNode = nil
                    
                    selectedDropper = dropper
                    selectedDropper?.strokeColor = .orange
                }
            }
        case .delete:
            var lineAtLocation = false
            var otherNodes : [SKNode] = []
            
            for node in nodes(at: location){
                if let line = node as? MusicLine{ // prioritise deleting lines over balls/droppers, reduces accidental deletions
                    if existingLines.contains(line) {
                        guard let index = existingLines.firstIndex(of: line) else { continue }
                        existingLines.remove(at: index)
                        line.removeFromParent()
                        
                        lineAtLocation = true
                        break
                    }
                } else {
                    otherNodes.append(node)
                }
            }
            
            if lineAtLocation == false {
                for node in otherNodes {
                    if let dropper = node as? Dropper{
                        if activeDroppers.contains(dropper) {
                            guard let index = activeDroppers.firstIndex(of: dropper) else { continue }
                            dropper.terminateTimer()
                            activeDroppers.remove(at: index)
                            
                            dropper.removeFromParent()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Collision and Sound
    func didBegin(_ contact: SKPhysicsContact) {
        if let line = contact.bodyA.node as? MusicLine {
            guard let musicBall = contact.bodyB.node as? MusicBall else { return }
            
            if musicBall.hasTouchedLine(line) { return } // already touched it, dont play sound again
            else { musicBall.touchedNewLine(line) }
            
            let instrument = line.instrument
            switch instrument {
            case .drum:
                let drumType = line.drumType ?? .kick
                playSound(drumType: drumType)
            case .piano, .guitar:
                let note = line.note ?? .c
                playSound(for: instrument, note: note)
            }
        } else if let line = contact.bodyB.node as? MusicLine {
            guard let musicBall = contact.bodyA.node as? MusicBall else { return }
            
            if musicBall.hasTouchedLine(line) { return } // already touched it, dont play sound again
            else { musicBall.touchedNewLine(line) }
            
            let instrument = line.instrument
            switch instrument {
            case .drum:
                let drumType = line.drumType ?? .kick
                playSound(drumType: drumType)
            case .piano, .guitar:
                let note = line.note ?? .c
                playSound(for: instrument, note: note)
            }
        }
    }
    
    private func playSound(for instrument: Instrument, note: MusicNote){
        let filename = note.rawValue + instrument.rawValue + ".mp3"
        
        //run(SKAction.playSoundFileNamed("\(filename).mp3", waitForCompletion: true))
        //guard let action = soundActions[filename] else { return }
        //run(action)
        run(soundActions[filename]!)
    }
    
    private func playSound(drumType: DrumType){
        let filename = drumType.rawValue + ".mp3"
        
        //guard let action = soundActions[filename] else { return }
        //run(action)
        run(soundActions[filename]!)
    }
    
    private func loadInstrumentSounds(){
        // load drums
        soundActions["Kick.mp3"] = SKAction.playSoundFileNamed("Kick.mp3", waitForCompletion: false)
        soundActions["Snare.mp3"] = SKAction.playSoundFileNamed("Snare.mp3", waitForCompletion: false)
        soundActions["Hat.mp3"] = SKAction.playSoundFileNamed("Hat.mp3", waitForCompletion: false)
        
        // load guitar
        soundActions["AGuitar.mp3"] = SKAction.playSoundFileNamed("AGuitar.mp3", waitForCompletion: false)
        soundActions["BGuitar.mp3"] = SKAction.playSoundFileNamed("BGuitar.mp3", waitForCompletion: false)
        soundActions["CGuitar.mp3"] = SKAction.playSoundFileNamed("CGuitar.mp3", waitForCompletion: false)
        soundActions["DGuitar.mp3"] = SKAction.playSoundFileNamed("DGuitar.mp3", waitForCompletion: false)
        soundActions["EGuitar.mp3"] = SKAction.playSoundFileNamed("EGuitar.mp3", waitForCompletion: false)
        soundActions["FGuitar.mp3"] = SKAction.playSoundFileNamed("FGuitar.mp3", waitForCompletion: false)
        soundActions["GGuitar.mp3"] = SKAction.playSoundFileNamed("GGuitar.mp3", waitForCompletion: false)
        
        // load piano
        soundActions["APiano.mp3"] = SKAction.playSoundFileNamed("APiano.mp3", waitForCompletion: false)
        soundActions["BPiano.mp3"] = SKAction.playSoundFileNamed("BPiano.mp3", waitForCompletion: false)
        soundActions["CPiano.mp3"] = SKAction.playSoundFileNamed("CPiano.mp3", waitForCompletion: false)
        soundActions["DPiano.mp3"] = SKAction.playSoundFileNamed("DPiano.mp3", waitForCompletion: false)
        soundActions["EPiano.mp3"] = SKAction.playSoundFileNamed("EPiano.mp3", waitForCompletion: false)
        soundActions["FPiano.mp3"] = SKAction.playSoundFileNamed("FPiano.mp3", waitForCompletion: false)
        soundActions["GPiano.mp3"] = SKAction.playSoundFileNamed("GPiano.mp3", waitForCompletion: false)
    }
    
    // controls when droppers are triggered
    private func gameTimer(){
        dropperTrigger = Timer(timeInterval: 0.5, target: self, selector: #selector(activateDroppers), userInfo: nil, repeats: true)
        RunLoop.current.add(dropperTrigger!, forMode: .common)
    }
    
    @objc private func activateDroppers(){
        for dropper in activeDroppers {
            if dropper.beatTrigger[beatCount] == true {
                dropper.spawnMusicBall()
            }
        }
        
        if beatCount >= 3 {
            beatCount = 0
        } else {
            beatCount += 1
        }

    }
    
    // MARK: Config for Game Mode and BPM
    public func setGameMode(to gameMode: GameMode){
        // reset selection and any lines points not yet drawn, edit mode has exceptions
        if gameMode != .edit {
            selectedLineNode?.strokeColor = .black
            selectedLineNode = nil
            
            selectedDropper?.strokeColor = .purple
            selectedDropper = nil
        }
        currentLine = []
        
        currentMode = gameMode
        print(currentMode)
        print(gameMode)
    }
    
    public func updateBPM(to bpm: Int){
        currentBPM = bpm
        let interval = 60.0 / Double(bpm)
        
        for dropper in activeDroppers {
            dropper.setTimerInterval(newInterval: interval)
        }
    }
    
}
