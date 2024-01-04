Widget {
    id: mattable
    property Object valueRef: nil
    property Array sources: nil
    property Array destinations: nil
    
    onExtern: {
        mattable.valueRef = OSC::RemoteParam.new($remote, mattable.extern)
        mattable.valueRef.mode = :options
    }
   
    function onSetup(old=nil)
    {

        meta = OSC::RemoteMetadata.new($remote, mattable.extern + "PSources")
        mattable.label   = meta.short_name
        mattable.tooltip = meta.tooltip
        if(meta.options)
            nopts = []
            meta.options.each do |x|
                nopts << x[1]
            end
            mattable.sources = nopts
        end

        meta = OSC::RemoteMetadata.new($remote, mattable.extern + "PDestinations")
        mattable.label   = meta.short_name
        mattable.tooltip = meta.tooltip
        if(meta.options)
            nopts = []
            meta.options.each do |x|
                nopts << x[1]
            end
            mattable.destinations = nopts
        end
        
        titles = Qml::ZynMatTitles.new(db)
        Qml::add_child(self, titles)
        mattable.sources.each_with_index do |src, index|
            row         = Qml::ZynMatRow.new(db)
            row.label   = src
            row.rownum  = index
            row.extern  = mattable.extern + "source#{index}/"
            Qml::add_child(self, row)
        end
    }

    function class_name() { "mattable" }
    function layout(l, selfBox) {
        Draw::Layout::vpack(l, selfBox, children)
    }

}
