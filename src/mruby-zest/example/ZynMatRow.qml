Widget {
    id: mat_row
    property Int rownum: nil
    property Int offset: 0

    function class_name() { "matrow" }
    function layout(l, selfBox) {
        Draw::Layout::hpack(l, selfBox, children)
    }
    
    Text {
        label: parent.sources[rownum]
    }

    function onSetup(old=nil)
    {

        parent.params.each_with_index do |param, i|
            knob         = Qml::Knob.new(db)
            knob.type    = :float
            knob.extern  = mat_row.extern + "location0/" + "parameter#{i}"
            Qml::add_child(self, knob)
        end
    }
    
    function switchLocation(location)
    {

        self.children[1..-1].each_with_index do |child, i|
            child.extern  = mat_row.extern + "location#{location}/" + "parameter#{i}"
        end
    }
}
