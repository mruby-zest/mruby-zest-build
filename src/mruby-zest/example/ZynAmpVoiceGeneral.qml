Group {
    id: box
    label: "General"
    copyable: false

    property Function whenModified: nil

    ParModuleRow {
        id: top
        Knob { extern: box.extern+"volume"; type: :float }
        Knob { extern: box.extern+"PAmpVelocityScaleFunction"}
        Col {
            BypassButton { extern: box.extern+"Pfilterbypass" }
            ToggleButton { label: "F. Ctl Bypass"; extern: box.extern+"PfilterFcCtlBypass"

            }
            function layout(l, selfBox) {
                Draw::Layout::vfill(l, selfBox, children, [0.6, 0.4])
            }

        }
    }
    ParModuleRow {
        id: bot
        Knob { extern: box.extern+"PPanning"}
        Knob { extern: box.extern+"PDelay"}
        ToggleButton   {label: "reson";  extern: box.extern+"Presonance"}
    }
}
