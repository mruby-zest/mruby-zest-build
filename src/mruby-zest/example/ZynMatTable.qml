Widget {
    id: mattable
    //0.2
    //                       0     1     2     3     4     5     6     7     8
    property Array weights: [0.05, 0.19, 0.15, 0.10, 0.15, 0.07, 0.07, 0.07, 0.15]

    function onSetup(old=nil)
    {
        return if children.length > 2
        (0...16).each do |r|
            row         = Qml::ZynMatRow.new(db)
            row.label   = (r+1).to_s
            row.matnum  = r
            row.weights = self.weights
            row.extern  = mattable.extern + "mat#{r}/"
            row.extern()
            row.set_active(false) if !self.active && r != 0
            Qml::add_child(self, row)
        end
    }

    Widget {
        //0 - source sel button
        ColorBox {bg: Theme::TitleBar}
        
        #~ (0...16).each do |r|
        #~ TextBox  {bg: Theme::TitleBar; label: "Dest 0"}
        #~ end
    }

    function class_name() { "mattable" }
    function layout(l, selfBox) {
        Draw::Layout::vpack(l, selfBox, children, 0, 1, 2)
    }

}
