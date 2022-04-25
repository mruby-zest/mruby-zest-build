Widget {
    id: mattable
    property Object valueRef: nil
    property Array sources: []
    property Array locations: []
    property Array params: []
    property Array tabs: []
    property Int curOff: 0
    property Int  oldOff: 0
    property Array rows: []
    property Object titleLine: nil
    
    Widget {
        id: header

        function layout(l, selfBox) {
            Draw::Layout::tabpack(l, selfBox, self)
        }
        
        function onSetup(old=nil) {
             mattable.locations.each_with_index do |loc, id|
                button           = Qml::TabButton.new(db)
                button.label     = loc
                button.value    = true if (id == 0)
                button.whenClick = lambda {parent.setTab(id)}
                Qml::add_child(self, button)
                parent.tabs << button
            end
        }
    }
    
    function setTab(id) {
        
        self.tabs.each_with_index do |tab, i|
            tab.value = (i==id)
            tab.damage_self
        end
        
        self.rows.each do |row|
            row.switchLocation(id)
            row.damage_self
        end
    }
    
    function onSetup(old=nil)
    {
        meta = OSC::RemoteMetadata.new($remote, mattable.extern + "PSources")
        mattable.label   = meta.short_name
        mattable.tooltip = meta.tooltip
        if(meta.options)
            mattable.sources = []
            meta.options.each do |x|
                mattable.sources << x[1]
            end
        end

        meta = OSC::RemoteMetadata.new($remote, mattable.extern + "PDestLocations")
        mattable.label   = meta.short_name
        mattable.tooltip = meta.tooltip
        if(meta.options)
            mattable.locations = []
            meta.options.each do |x|
                mattable.locations << x[1]
            end
        end
        
        meta = OSC::RemoteMetadata.new($remote, mattable.extern + "PDestParameters")
        mattable.label   = meta.short_name
        mattable.tooltip = meta.tooltip
        if(meta.options)
            mattable.params = []
            meta.options.each do |x|
                mattable.params << x[1]
            end
        end
        
        self.titleLine = Qml::ZynMatTitles.new(db)
        Qml::add_child(self, titleLine)
       
        mattable.sources.each_with_index do |src, index|
            row         = Qml::ZynMatRow.new(db)
            row.label   = src
            row.rownum  = index
            row.extern  = mattable.extern + "source#{index}/"
            rows << row
            Qml::add_child(self, row)
        end
    }

    function class_name() { "mattable" }
    function layout(l, selfBox) {
        Draw::Layout::vpack(l, selfBox, children)
    }
    
    onExtern: {
        mattable.valueRef = OSC::RemoteParam.new($remote, mattable.extern)
        mattable.valueRef.mode = :options
    }

}
