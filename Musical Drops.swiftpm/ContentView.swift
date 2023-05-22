import SwiftUI
import SpriteKit

struct ContentView: View {
    
    @ObservedObject var scene: GameScene = GameScene()
    
    @State private var selectedGameMode : GameMode = .drawLines
    @State private var selectedBPM : Int = 120
    
    @State private var lineNodeSelected = false
    @State private var dropperSelected = false
    
    // instruments
    @State private var drumsOn = false
    @State private var pianoOn = false
    @State private var guitarOn = false
    
    @State private var selectedDrumType : DrumType = .kick
    @State private var selectedPianoNote : MusicNote = .c
    @State private var selectedGuitarNote : MusicNote = .c
    
    // dropper config
    @State private var selectedTriggers : [Int] = []
    @State private var firstBeat : Bool = false
    @State private var secondBeat : Bool = false
    @State private var thirdBeat : Bool = false
    @State private var fourthBeat : Bool = false
    
    var body: some View {
        VStack {
            VStack{
                // game view
                SpriteView(scene: scene, transition: nil, isPaused: false, preferredFramesPerSecond: 30)
                
                HStack{
                    VStack{
                        Text("Toggle Mode")
                        Picker("Mode Picker", selection: $selectedGameMode) {
                            Text("Edit").tag(GameMode.edit)
                            Text("Draw Line").tag(GameMode.drawLines)
                            Text("Create Dropper").tag(GameMode.createDropper)
                            Text("Delete").tag(GameMode.delete)
                        }.pickerStyle(.segmented)
                    }.padding(8)
                    
                    Divider()
                    
                    VStack{
                        Text("Dropper Timing")
                        HStack{
                            Toggle("1st Beat", isOn: $firstBeat)
                            Toggle("2nd Beat", isOn: $secondBeat)
                            Toggle("3rd Beat", isOn: $thirdBeat)
                            Toggle("4th Beat", isOn: $fourthBeat)
                        }

                    }.disabled(!dropperSelected)
                        .opacity(dropperSelected ? 1 : 0.5)
                        .padding(8)
                    
                    Divider()
                    
                    VStack{
                        Text("Sound")
                        
                        HStack{
                            VStack{
                                Toggle(isOn: $drumsOn) {
                                    Text("Drums")
                                }
                                
                                Picker("Mode Picker", selection: $selectedDrumType) {
                                    Text("Kick").tag(DrumType.kick)
                                    Text("Snare").tag(DrumType.snare)
                                    Text("Hat").tag(DrumType.hat)
                                }.pickerStyle(.menu)
                                    .disabled(!drumsOn)
                                    .opacity(drumsOn ? 1 : 0.5)
                            }
                            VStack{
                                Toggle(isOn: $pianoOn) {
                                    Text("Piano")
                                }
                                
                                Picker("Note", selection: $selectedPianoNote) {
                                    Text("A").tag(MusicNote.a)
                                    Text("B").tag(MusicNote.b)
                                    Text("C").tag(MusicNote.c)
                                    Text("D").tag(MusicNote.d)
                                    Text("E").tag(MusicNote.e)
                                    Text("F").tag(MusicNote.f)
                                    Text("G").tag(MusicNote.g)
                                }.pickerStyle(.menu)
                                    .disabled(!pianoOn)
                                    .opacity(pianoOn ? 1 : 0.5)
                            }
                            VStack{
                                Toggle(isOn: $guitarOn) {
                                    Text("Guitar")
                                }
                                
                                Picker("Note", selection: $selectedGuitarNote) {
                                    Text("A").tag(MusicNote.a)
                                    Text("B").tag(MusicNote.b)
                                    Text("C").tag(MusicNote.c)
                                    Text("D").tag(MusicNote.d)
                                    Text("E").tag(MusicNote.e)
                                    Text("F").tag(MusicNote.f)
                                    Text("G").tag(MusicNote.g)
                                }.pickerStyle(.menu)
                                    .disabled(!guitarOn)
                                    .opacity(guitarOn ? 1 : 0.5)
                            }
                        }
                        
                    }.disabled(!lineNodeSelected)
                        .opacity(lineNodeSelected ? 1 : 0.5)
                        .padding(8)
                    
                }.frame(maxWidth: .infinity, maxHeight: 150)
                    .background(Color("ControlBackground"))
            }
        }
        // MARK: Game Changes
        .onChange(of: selectedGameMode) { newGameMode in
            scene.setGameMode(to: newGameMode)
        }
        .onChange(of: selectedBPM, perform: { newBPM in
            scene.updateBPM(to: newBPM)
        })
        .onChange(of: scene.selectedLineNode, perform: { lineNode in
            if lineNode == nil {
                lineNodeSelected = false
            } else {
                lineNodeSelected = true
                dropperSelected = false
            }
            
            // run this regardless, as it turns all toggles off if there isnt a selected node
            getLineInstrument()
        })
        .onChange(of: scene.selectedDropper, perform: { dropperNode in
            if dropperNode == nil {
                dropperSelected = false
            } else {
                dropperSelected = true
                lineNodeSelected = false
            }
            
            getDropperTriggers()
        })
        
        // MARK: Instrument Toggle Changes
        .onChange(of: drumsOn, perform: { drumsToggled in
            if drumsToggled {
                guitarOn = false
                pianoOn = false
                
                scene.selectedLineNode?.instrument = .drum
            } else if (!drumsOn && !pianoOn && !guitarOn) {
                drumsOn = true
                guitarOn = false
                pianoOn = false
            }
        })
        .onChange(of: pianoOn, perform: { pianoToggled in
            if pianoToggled {
                drumsOn = false
                guitarOn = false
                
                scene.selectedLineNode?.instrument = .piano
            } else if (!drumsOn && !pianoOn && !guitarOn) {
                drumsOn = false
                guitarOn = false
                pianoOn = true
            }
        })
        .onChange(of: guitarOn, perform: { guitarToggled in
            if guitarToggled {
                drumsOn = false
                pianoOn = false
                
                scene.selectedLineNode?.instrument = .guitar
            } else if (!drumsOn && !pianoOn && !guitarOn) {
                drumsOn = false
                guitarOn = true
                pianoOn = false
            }
        })
        
        // MARK: Instrument Property Changes
        .onChange(of: selectedDrumType, perform: { newDrumType in
            if let line = scene.selectedLineNode {
                line.drumType = newDrumType
            }
        })
        .onChange(of: selectedPianoNote, perform: { newPianoNote in
            if let line = scene.selectedLineNode {
                line.note = newPianoNote
            }
        })
        .onChange(of: selectedGuitarNote, perform: { newGuitarNote in
            if let line = scene.selectedLineNode {
                line.note = newGuitarNote
            }
        })
        
        // MARK: Dropper Config Changes
        .onChange(of: [firstBeat, secondBeat, thirdBeat, fourthBeat], perform: { newTriggers in
            if let dropper = scene.selectedDropper {
                dropper.beatTrigger = newTriggers
            }
        })
        
        .onAppear {
            scene.size = CGSize(width: 1280, height: 720)
            scene.scaleMode = .aspectFit
            scene.backgroundColor = .white
        }
    }
    
    func getLineInstrument(){
        drumsOn = false
        pianoOn = false
        guitarOn = false
        
        if let line = scene.selectedLineNode {
            switch line.instrument {
            case .drum:
                drumsOn = true
                selectedDrumType = line.drumType ?? .kick
            case .piano:
                pianoOn = true
                selectedPianoNote = line.note ?? .c
            case .guitar:
                guitarOn = true
                selectedGuitarNote = line.note ?? .c
            }
        }
    }
    
    func getDropperTriggers(){
        firstBeat = false
        secondBeat = false
        thirdBeat = false
        fourthBeat = false
        
        if let dropper = scene.selectedDropper {
            firstBeat = dropper.beatTrigger[0]
            secondBeat = dropper.beatTrigger[1]
            thirdBeat = dropper.beatTrigger[2]
            fourthBeat = dropper.beatTrigger[3]
        }
    }
}
