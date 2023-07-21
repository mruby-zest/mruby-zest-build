Group {
    id: hysteresis
    label: "hysteresis"
    topSize: 0.2
    function refresh() {
        return if rw.content.nil?
        return if rw.content.children.length < 4
        rw.content.children[4..-1].each do |c|
            c.refresh
        end
    }

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
        Knob { extern: hysteresis.extern + "Hysteresis/Pdrive"   }
        Knob { extern: hysteresis.extern + "Hysteresis/Premanence"   }
        Knob { extern: hysteresis.extern + "Hysteresis/Pcoercivity" }

    }
}
