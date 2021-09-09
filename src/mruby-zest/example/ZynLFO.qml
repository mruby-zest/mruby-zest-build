Group {
    id: box
    label: "LFO"
    extern: ""
    copyable: true

    Widget {
    function layout(l, selfBox) {
            Draw::Layout::hfill(l, selfBox, children, [0.72, 0.28])
        }
    
        Col {
            ParModuleRow {
                id: top
                Knob { type: :float; extern: box.extern+"freq" }
                Knob { extern: box.extern+"Pintensity"}
                Knob { extern: box.extern+"Pcutoff"}
                Knob { extern: box.extern+"Pstartphase"}
                Knob { extern: box.extern+"Pstretch"}

            }
            ParModuleRow {
                id: bot
                Knob     { type: :float; extern: box.extern+"delay"}
                Knob     { type: :float; extern: box.extern+"fadein"}
                Knob     { type: :float; extern: box.extern+"fadeout"}
                Knob     {extern: box.extern+"Prandomness"}
                Knob     {extern: box.extern+"Pfreqrand"}
            }
        }
        Col {
            Selector {extern: box.extern+"PLFOtype"}
            ToggleButton   { label: "sync"; extern: box.extern+"Pcontinous"}
            NumEntry {extern: box.extern + "numerator"; label: "Numerator"}
            NumEntry {extern: box.extern + "denominator"; label: "Denominator"}
        }
    }
}
