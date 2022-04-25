Widget {
    id: mat_titles
    property Int size: nil
    property boolean vertical: nil
    
    

    function class_name() { "mattitles" }
    function layout(l, selfBox) {
        Draw::Layout::hpack(l, selfBox, children) 
        Draw::Layout::vpack(l, selfBox, children) if (vertical)
        
    }
    
    function onSetup(old=nil)
    {
        title = Qml::Text.new(db)
        title.label   = "Src \ Dst"
        Qml::add_child(self, title) if (!vertical)
        parent.params.each do |par|
            title         = Qml::Text.new(db)
            title.label   = par
            Qml::add_child(self, title)
        end
    }
}
