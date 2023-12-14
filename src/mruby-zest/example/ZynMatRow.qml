Widget {
    id: mat_row
    property Array weights: [0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10]
    property Int rownum: nil

    function class_name() { "matrow" }
    function layout(l, selfBox) {
        Draw::Layout::hpack(l, selfBox, children)
    }
    
    Text {
        label: parent.sources[rownum]
    }

    function onSetup(old=nil)
    {

        parent.destinations.each_with_index do |d, r|
            knob         = Qml::Knob.new(db)
            knob.label   = d
            knob.extern  = mat_row.extern + "col#{r}/"
            Qml::add_child(self, knob)
        end
    }
}
