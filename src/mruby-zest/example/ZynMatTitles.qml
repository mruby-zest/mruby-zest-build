Widget {
    id: mat_titles
    property Int size: nil
    property boolean vertical: nil
    
    

    function class_name() { "MatTitles" }
    function layout(l, selfBox) {
        Draw::Layout::hpack(l, selfBox, children) 
        Draw::Layout::vpack(l, selfBox, children) if (vertical)
        
    }
    
    function onSetup(old=nil)
    {
        title = Qml::Text.new(db)
        title.label   = "Src \ Dst"
        Qml::add_child(self, title) if (!vertical)
        parent.destinations.each_with_index do |d, r|

            title         = Qml::Text.new(db)
            title.label   = d
            Qml::add_child(self, title)
            
        end
    }
}
