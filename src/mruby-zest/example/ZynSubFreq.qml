Widget {
    id: subfq
    extern: "/part0/kit0/subpars/"
    //visual
    ZynEnvEdit {
        id: edit
        extern: subfq.extern + "FreqEnvelope/"
    }
    Widget {
        Group {
            label: "general"
            ParModuleRow {
                Knob {     extern: subfq.extern + "PDetune" }
                Selector { extern: subfq.extern + "PDetuneType" }
                NumEntry { extern: subfq.extern + "octave" }
                Knob     { extern: subfq.extern + "PBendAdjust"}
                //eqt

            }
            ParModuleRow {
                ToggleButton {   extern: subfq.extern + "Pfixedfreq" }
                Knob   {   extern: subfq.extern + "PfixedfreqET" }
                Knob     { extern: subfq.extern + "POffsetHz"}
            }
        }
        ZynFreqEnv {
            toggleable: subfq.extern + "PFreqEnvelopeEnabled"
            extern: subfq.extern+"FreqEnvelope/"
            whenModified: lambda { edit.refresh }
        }
        function layout(l, selfBox) {
            Draw::Layout::hpack(l, selfBox, children)
        }
    }
    function layout(l, selfBox) {
        Draw::Layout::vfill(l, selfBox, children, [0.6, 0.4])
    }
}
