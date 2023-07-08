Group {
    id: reverse
    label: "reverse"
    topSize: 0.2
    ParModuleRow {
        id: rw
        layoutOpts: []
        Knob { extern: reverse.extern + "Pvolume"}
        Knob { extern: reverse.extern + "Ppanning"}
        Knob { id: delay extern: reverse.extern + "Reverse/Pdelay"   }
        Col {
            NumEntry {extern: reverse.extern + "numerator"; 
                value: 0
                label: "Numerator"
                whenValue: lambda { delay.refresh }
            }
            NumEntry {extern: reverse.extern + "denominator"; 
                value: 4
                label: "Denominator"
                whenValue: lambda { delay.refresh }}
        }
        ToggleButton { extern: reverse.extern + "Reverse/Pstereo"}
    }
}
