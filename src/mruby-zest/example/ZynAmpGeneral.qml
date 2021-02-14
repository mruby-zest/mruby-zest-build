Group {
    id: box
    label: "General"
    copyable: false
    property Function whenModified: nil

    ParModuleRow {
        id: top
        Knob { 
            extern: box.extern+"Volume"
            type:   :float
        }
        Knob { extern: box.extern+"PAmpVelocityScaleFunction"}
        Knob { extern: box.extern+"PPanning"}
        Knob { extern: box.extern+"PPunchStretch"}

    }
    ParModuleRow {
        id: bot
        Knob     {extern: box.extern+"PPunchStrength"}
        Knob     {extern: box.extern+"PPunchTime"}
        Col {
            ToggleButton   {label: "stereo"; extern: box.extern+"PStereo"}
            ToggleButton   {label: "rnd grp"; extern: box.extern+"Hrandgrouping"}
        }
    }
}
