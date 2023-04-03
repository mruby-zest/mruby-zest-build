Group {
    label: "instrument settings"
    copyable: false
    id: insset
    Widget {
        ParModuleRow {
            whitespace: 2
            Knob {
                type: :float
                label: "volume"
                extern: insset.extern + "Volume"
            }
            Knob { extern: insset.extern + "Ppanning"}
            Knob {
                id: minkey
                label: "min key"
                extern: insset.extern + "Pminkey"
            }
            Knob {
                id: maxkey
                label: "max key"
                extern: insset.extern + "Pmaxkey"
            }
        }
        ParModuleRow {
            whitespace: 3
            outer: :none
            layoutOpts: []
            Knob {
                label "vel sense"
                extern: insset.extern + "Pvelsns"
            }
            Knob {
                label: "vel offset"
                extern: insset.extern + "Pveloffs"
            }
            Knob {
                label: "key shift"
                extern: insset.extern + "Pkeyshift"
            }
            ZynKitKeyButton {
                layoutOpts: [:aspect]
                extern: insset.extern
                whenValue: lambda {
                    minkey.refresh
                    maxkey.refresh
                }
            }
        }
        ParModuleRow {
            lsize: 0.0
            Selector     {
                extern: insset.extern + "Prcvchn";
                label: "midi chan"
            }
            Selector {
                extern: insset.extern + "polyType";
                label: "mode";
                layoutOpts: [:no_constraint, :long_mode]
            }
            TextBox {
                label: vlimit.label
            }
            NumEntry {
                id: vlimit;
                extern: insset.extern + "Pvoicelimit";
                label: "Voice Limit"
            }
        }
        function layout(l, selfBox) {
            Draw::Layout::vfill(l, selfBox, children, [0.40, 0.40,0.2],0,2)
        }
    }
}
