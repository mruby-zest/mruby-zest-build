Group {
    id: port
    label: "portamento"
    copyable: false
    ParModuleRow {
        ToggleButton {
            extern: port.extern+"portamento.receive"
        }
        Text { }
        ToggleButton {
            extern: port.extern+"portamento.portamento"
            label: "enable"
        }
        Knob   { extern: port.extern+"portamento.time"}
        Knob   { extern: port.extern+"portamento.updowntimestretch"}
    }
    ParModuleRow {
        ToggleButton {
            extern: port.extern+"portamento.pitchthreshtype"
        }
        NumEntry {
            extern: port.extern+"portamento.pitchthresh"
        }
        ToggleButton {
            extern: port.extern+"portamento.proportional"
            label: "prop."
        }
        Knob   { extern: port.extern+"portamento.propRate"}
        Knob   { extern: port.extern+"portamento.propDepth"}
    }
}
