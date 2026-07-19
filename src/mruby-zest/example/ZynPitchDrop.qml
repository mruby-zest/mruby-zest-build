Group {
    id: pitchdrop
    label: "PitchDrop"
    topSize: 0.2

    ParModuleRow {
        id: rw
        layoutOpts: []
        Selector {
            extern: pitchdrop.extern + "PitchDrop/preset"
        }
        Knob { extern: pitchdrop.extern + "Pvolume"}
        Knob { extern: pitchdrop.extern + "Ppanning"}
        Knob { extern: pitchdrop.extern + "PitchDrop/PdropRate"}
        Knob { extern: pitchdrop.extern + "PitchDrop/PmaxDrop"}
        Knob { extern: pitchdrop.extern + "PitchDrop/PfadingTime"}
        Knob { extern: pitchdrop.extern + "PitchDrop/PfreqOffset"}
        Knob { extern: pitchdrop.extern + "PitchDrop/Plfodepth"}
        Knob { extern: pitchdrop.extern + "PitchDrop/lfo.Pfreq"}
        Knob { extern: pitchdrop.extern + "PitchDrop/lfo.Prandomness"}
        Selector { extern: pitchdrop.extern + "PitchDrop/lfo.PLFOtype"}
        
    }
}