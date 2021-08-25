Group {
    id: echo
    label: "echo"
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
            extern: echo.extern + "Echo/preset"
            whenValue: lambda { echo.refresh }
        }
        Knob { extern: echo.extern + "Pvolume"}
        Knob { extern: echo.extern + "Ppanning"}
        Col {
            NumEntry {extern: echo.extern + "numerator"; 
                value: 0
                label: "Numerator"
                whenValue: lambda { echo.refresh }
            }
            NumEntry {extern: echo.extern + "denominator"; 
                value: 4
                label: "Denominator"
                whenValue: lambda { echo.refresh }}
        }
        Knob { extern: echo.extern + "Echo/Pdelay"   }
        Knob { extern: echo.extern + "Echo/Plrdelay" }
        Knob { extern: echo.extern + "Echo/Plrcross" }
        Knob { extern: echo.extern + "Echo/Pfb" }
        Knob { extern: echo.extern + "Echo/Phidamp" }
    }
}
