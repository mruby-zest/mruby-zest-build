Widget {
    id: mat_row
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

        parent.destinations.each_with_index do |dest, index|
            knob         = Qml::Knob.new(db)
            knob.label   = dest
            knob.extern  = mat_row.extern + "destination#{index}/"
            Qml::add_child(self, knob)
        end
    }
}
