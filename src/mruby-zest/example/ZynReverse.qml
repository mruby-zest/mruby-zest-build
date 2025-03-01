Group {
    id: reverse
    label: "reverse"
    topSize: 0.2
    function refresh() {
        return if rw.content.nil?
        return if rw.content.children.length < 5
        rw.content.children[4..-1].each do |c|
            c.refresh
        end
    }

    ParModuleRow {
        id: rw
        layoutOpts: []
        Selector {
            extern: reverse.extern + "Reverse/preset"
            layoutOpts: [:long_mode]
            whenValue: lambda { reverse.refresh }
        }
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
        ToggleButton { extern: reverse.extern + "Reverse/Pstereo"}
        Selector {
                    id: sm
                    extern: reverse.extern + "Reverse/Psyncmode";
                    layoutOpts: [:long_mode]
                    whenValue: lambda {
                        delay.active = true if sm.selected != 1
                        delay.active = false if sm.selected == 1
                        delay.damage_self
                    }
                }
        
    }
}
