Group {
    id: box
    label: "SEQ"
    extern: ""
    copyable: true

    
    Widget {
        function layout(l, selfBox) {
            Draw::Layout::hfill(l, selfBox, children, [0.65, 0.35])
        }

        Col {
            ParModuleRow {
                id: top
                Knob { id: freq; type: :float; extern: box.extern+"freq" }
                Knob { type: :float; extern: box.extern+"cutoff"}
            }
            ParModuleRow {
                id: bot
                Knob { type: :float; extern: box.extern+"delay"}
                Knob { type: :float; extern: box.extern+"intensity" }
                }
        }
        Col {
            function layout(l, selfBox) {
                Draw::Layout::vfill(l, selfBox, children, [0.5, 0.15, 0.15])
            }
            ToggleButton   { label: "sync"; extern: box.extern+"continous"}
            
            NumEntry {
                id: numerator
                extern: box.extern + "numerator"; 
                label: "Numerator"
                whenValue: lambda {
                    freq.active = true if numerator.value == 0
                    freq.active = false if numerator.value != 0
                    box.damage_self
                }
            }
            NumEntry {extern: box.extern + "denominator"; label: "Denominator"}
        }
    }
}
