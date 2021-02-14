Group {
    id: box
    label: "General"
    copyable: false

    property Function whenModified: nil

    ParModuleRow {
        id: top
        Knob { extern: box.extern+"volume"; type: :float }
        Knob { extern: box.extern+"PAmpVelocityScaleFunction"}
        BypassButton { extern: box.extern+"Pfilterbypass" }

    }
    ParModuleRow {
        id: bot
        Knob { extern: box.extern+"PPanning"}
        Knob { extern: box.extern+"PDelay"}
        ToggleButton   {label: "reson";  extern: box.extern+"Presonance"}
    }
}
