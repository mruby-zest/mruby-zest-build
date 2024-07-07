Group {
    id: reverse
    label: "reverse"
    topSize: 0.2
    function refresh() {
        return if rw.content.nil?
        return if rw.content.children.length < 4
        rw.content.children[3..-1].each do |c|
            c.refresh
        end
    }

    ParModuleRow {
        id: rw
        layoutOpts: []
        Knob { extern: reverse.extern + "Pvolume"}
        Knob { extern: reverse.extern + "Ppanning"}
        Col {
            NumEntry {extern: reverse.extern + "numerator"; 
                id: num
                value: 0
                label: "Numerator"
                whenValue: lambda { reverse.refresh } 
            }
            NumEntry {extern: reverse.extern + "denominator"; 
                id: den
                value: 4
                label: "Denominator"
                whenValue: lambda { reverse.refresh }
            }
        }
        Knob { 
            id: delay 
            extern: reverse.extern + "Reverse/Pdelay"   
        }
        Knob { 
            id: phase 
            extern: reverse.extern + "Reverse/Pphase"   
        }
        Knob { 
            id: fade 
            extern: reverse.extern + "Reverse/Pcrossfade"   
        }
        Selector {
                    id: sm
                    extern: reverse.extern + "Reverse/Psyncmode";
                    layoutOpts: [:long_mode]
                }
        ToggleButton { extern: reverse.extern + "Reverse/Pstereo"}
    }
}
