Group {
    id: chorus
    label: "chorus"
    topSize: 0.2

    function refresh() {
        return if rw.content.nil?
        return if rw.content.children.length < 4
        rw.content.children[4..-1].each do |c|
            c.refresh
        end
    }

    ParModuleRow {
        id: rw
        layoutOpts: []
        Selector {
            extern: chorus.extern + "Chorus/preset"
            whenValue: lambda { chorus.refresh }
        }
        Knob { extern: chorus.extern + "Pvolume"}
        Knob { extern: chorus.extern + "Ppanning"}
        Col {
            NumEntry {extern: chorus.extern + "numerator"; 
                label: "Numerator"
                value: 0
                whenValue: lambda { chorus.refresh }
            }
            NumEntry {extern: chorus.extern + "denominator"; 
                label: "Denominator"
                value: 4
                whenValue: lambda { chorus.refresh }
            }
        } 
        Knob { extern: chorus.extern + "Chorus/Pfreq" }
        Knob { extern: chorus.extern + "Chorus/Pfreqrnd" }
        Selector { extern: chorus.extern + "Chorus/PLFOtype" }
        Knob { extern: chorus.extern + "Chorus/PStereo" }
        Knob { extern: chorus.extern + "Chorus/Pdepth" }
        Knob { extern: chorus.extern + "Chorus/Pdelay" }
        Knob { extern: chorus.extern + "Chorus/Pfeedback" }
        Knob { extern: chorus.extern + "Chorus/Plrcross" }
        Selector { extern: chorus.extern + "Chorus/Pflangemode" }
        ToggleButton { extern: chorus.extern + "Chorus/Poutsub" }
    }
}

