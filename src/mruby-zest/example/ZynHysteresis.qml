Widget {
    id: hysteresis
    label: "hysteresis"
    topSize: 0.2
    function refresh_recur(x) {
        #@@recur_level ||= 0
        #@@recur_level += 1
        #print " "*@@recur_level
        #puts "Distort refresh = {#{x.class}} of {#{dst.class}}"
        x.children.each do |xx|
            #print " "*(@@recur_level+1)
            #puts "child = #{xx.class}"
            xx.refresh() if xx.respond_to? :refresh
            dst.refresh_recur(xx)
        end
        #@@recur_level -= 1
    }
    function refresh() {
        refresh_recur(self)
    }
    GroupHeader {
        label: "Hysteresis"
        extern: hysteresis.extern
        copyable: true
    }

    Widget {
        WaveView {
            id: wave
            extern: hysteresis.extern + "Hysteresis/waveform"
        }
        Widget {
            ParModuleRow {
                id: rw
                layoutOpts: []
                Selector {
                    layoutOpts: [:long_mode]
                    extern: hysteresis.extern + "Hysteresis/preset"
                    whenValue: lambda { hysteresis.refresh }
                }
                Knob { extern: hysteresis.extern + "Pvolume"}
                Knob { extern: hysteresis.extern + "Ppanning"}
                ToggleButton { label: "Stereo";  extern: hysteresis.extern + "Hysteresis/PStereo" }

            }
            ParModuleRow {
                id: rw2
                layoutOpts: []
                Knob { extern: hysteresis.extern + "Hysteresis/Pdrive"   }
                Knob { extern: hysteresis.extern + "Hysteresis/Pcoercivity" }
                Knob { extern: hysteresis.extern + "Hysteresis/Premanence"   }
                Knob { extern: hysteresis.extern + "Hysteresis/Plevel"   }

            }
            function layout(l, selfBox) {
                Draw::Layout::vpack(l, selfBox, children)
            }
        }

        function layout(l, selfBox) {
            Draw::Layout::hpack(l, selfBox, children)
        }
    }
    function layout(l, selfBox) {
        Draw::Layout::vfill(l, selfBox, children, [0.15, 0.85])
    }
}
