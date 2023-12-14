Widget {
    id: mattable
    //0.2
    //                       0     1     2     3     4     5     6     7     8
    property Array weights: [0.05, 0.19, 0.15, 0.10, 0.15, 0.07, 0.07, 0.07, 0.15]

    
    function onSetup(old=nil)
    {
        (0...16).each do |r|
            row         = Qml::ZynMatRow.new(db)
            row.label   = (r+1).to_s
            row.rownum  = r
            row.extern  = mattable.extern + "row#{r}/"
            Qml::add_child(self, row)
        end
    }

    function class_name() { "mattable" }
    function layout(l, selfBox) {
        Draw::Layout::vpack(l, selfBox, children, 0, 1, 2)
    }

}
