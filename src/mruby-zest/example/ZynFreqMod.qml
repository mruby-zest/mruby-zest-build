Group {
    id: box
    label: "General"
    ParModuleRow {
        Knob { extern: box.extern + "PFMDetune" }
        NumEntry { extern: box.extern + "FMoctave" }
        ToggleButton { extern: box.extern + "PFMFixedFreq" }
    }

    ParModuleRow {
        Selector { extern: box.extern + "PFMDetuneType" }
        Knob { extern: box.extern + "PFMCoarseDetune" }
    }
}
