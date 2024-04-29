Widget {
    id: hysteresis
    //label: "hysteresis"
    //topSize: 0.2
    function refresh_recur(x) {
        #@@recur_level ||= 0
        #@@recur_level += 1
        #print " "*@@recur_level
        #puts "hysteresis refresh = {#{x.class}} of {#{hysteresis.class}}"
        x.children.each do |xx|
            #print " "*(@@recur_level+1)
            #puts "child = #{xx.class}"
            xx.refresh() if xx.respond_to? :refresh
            hysteresis.refresh_recur(xx)
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
        HysteresisView {
            id: wave
            extern: hysteresis.extern + "Hysteresis/waveform"
        }
        Widget {
            ParModuleRow {
                id: rw
                layoutOpts: []
                Knob { extern: hysteresis.extern + "Pvolume"
                    whenValue: lambda {wave.refresh};
                    function setValue(v) {
                        valuator.value = lim(v, 0.0, 1.0);
                        valuator.whenValue.call;
                        valuator.damage_self
                    }
                }
                Knob { extern: hysteresis.extern + "Ppanning"}
                ToggleButton { label: "Stereo";  extern: hysteresis.extern + "Hysteresis/PStereo" }
            }
            ParModuleRow {
                id: rw2
                layoutOpts: []
                Knob { extern: hysteresis.extern + "Hysteresis/Pdrive"   
                    whenValue: lambda {wave.refresh};
                    function setValue(v) {
                        valuator.value = lim(v, 0.0, 1.0);
                        valuator.whenValue.call;
                        valuator.damage_self
                    }
                }
                Knob {
                    extern: hysteresis.extern + "Hysteresis/Pcoercivity"; label: "coercivity";
                    whenValue: lambda {wave.refresh};
                    function setValue(v) {
                        valuator.value = lim(v, 0.0, 1.0);
                        valuator.whenValue.call;
                        valuator.damage_self
                    }
                    }
                
                Knob {
                    extern: hysteresis.extern + "Hysteresis/Premanence"; label: "remanence";
                    whenValue: lambda {wave.refresh};
                    function setValue(v) {
                        valuator.value = lim(v, 0.0, 1.0);
                        valuator.whenValue.call;
                        valuator.damage_self
                    }
                    }
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
