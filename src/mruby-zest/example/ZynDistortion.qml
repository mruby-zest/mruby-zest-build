Widget {
    id: dst
    //label: "distortion"
    //topSize: 0.2
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
        label: "Distortion"
        extern: dst.extern
        copyable: true
    }
    Widget {
        WaveView {
            id: wave
            extern: dst.extern + "Distortion/waveform"
        }
        Widget {
            ParModuleRow {
                id: rw
                layoutOpts: []

                Selector {
                    extern: dst.extern + "Distortion/preset"
                    whenValue: lambda { dst.refresh }
                    layoutOpts: [:long_mode]
                }
                Knob {
                    extern: dst.extern + "Pvolume"
                    whenValue: lambda {wave.refresh};
                    }
                Knob { extern: dst.extern + "Ppanning"}
                Knob {   extern: dst.extern + "Distortion/Plrcross"; label: "l.rc." }
                Knob {   extern: dst.extern + "Distortion/Plpf"}
                Knob {   extern: dst.extern + "Distortion/Phpf"}

            }
            ParModuleRow {
                id: rw2
                layoutOpts: []
                Selector {
                    extern: dst.extern + "Distortion/Ptype";
                    whenValue: lambda {wave.refresh; funcpar.refresh}
                    layoutOpts: [:long_mode]
                }
                Knob {
                    extern: dst.extern + "Distortion/Pdrive"; label: "drive";
                    whenValue: lambda {wave.refresh};
                    function setValue(v) {
                        valuator.value = valuator.unclValue = lim(v, 0.0, 1.0);
                        valuator.whenValue.call;
                        valuator.damage_self
                    }
                }
                Knob {
                    extern: dst.extern + "Distortion/Poffset"; label: "DC";
                    whenValue: lambda {wave.refresh};
                    function setValue(v) {
                        valuator.value = valuator.unclValue = lim(v, 0.0, 1.0);
                        valuator.whenValue.call;
                        valuator.damage_self
                    }
                }
                Knob {
                    extern: dst.extern + "Distortion/Pfuncpar"; label: "shape";
                    id: funcpar
                    whenValue: lambda {wave.refresh};
                    function setValue(v) {
                        valuator.value = valuator.unclValue = lim(v, 0.0, 1.0);
                        valuator.whenValue.call;
                        valuator.damage_self
                    }
                }
                Knob {   extern: dst.extern + "Distortion/Plevel"; label: "level" }
                Col {
                    ToggleButton { extern: dst.extern + "Distortion/Pprefiltering"}
                    ToggleButton { extern: dst.extern + "Distortion/Pstereo"}
                }
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
