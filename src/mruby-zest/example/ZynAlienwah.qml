Group {
    id: wah
    label: "alienwah"
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
            extern: wah.extern + "Alienwah/preset"
            whenValue: lambda { wah.refresh }
        }
        Knob { extern: wah.extern + "Pvolume"}
        Knob { extern: wah.extern + "Ppanning"}
        Col {
            NumEntry {
                extern: wah.extern + "numerator"; 
                value: 0
                label: "Numerator"
            }
            NumEntry {
                extern: wah.extern + "denominator";
                value: 4
                label: "Denominator"
            }
        } 
        Knob { extern: wah.extern + "Alienwah/Pfreq"   }
        Knob { extern: wah.extern + "Alienwah/Pfreqrnd"   }
        Selector     { extern: wah.extern + "Alienwah/PLFOtype" }
        Knob { extern: wah.extern + "Alienwah/PStereo" }
        Knob { extern: wah.extern + "Alienwah/Pdepth" }
        Knob { extern: wah.extern + "Alienwah/Pfeedback" }
        Knob { extern: wah.extern + "Alienwah/Pdelay" }
        Knob { extern: wah.extern + "Alienwah/Plrcross" }
        Knob { extern: wah.extern + "Alienwah/Pphase" }
    }
}
