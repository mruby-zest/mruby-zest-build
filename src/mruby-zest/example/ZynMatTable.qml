Widget {
    id: mattable

    property Array sources: ["Sdfg","Sasdfa","Sdffrrr","rdfgsa","fdgdf","asdfa","dffrrr","rdfgsa","fdgdf","asdfa","dffrrr","rdfgsa","fdgdf"]
    property Array destinations: ["Ddfg","Easdfa","Udffrrr","Drdfgsa","Dfdgdf","Dasdfa","dffrrr","rdfgsa","fdgdf","asdfa","dffrrr","rdfgsa","fdgdf"]


    
    function onSetup(old=nil)
    {
    
        sources.each_with_index do |s, index|
            row         = Qml::ZynMatRow.new(db)
            row.label   = s
            row.rownum  = index
            row.extern  = mattable.extern + "row#{index}/"
            Qml::add_child(self, row)
        end
    }

    function class_name() { "mattable" }
    function layout(l, selfBox) {
        Draw::Layout::vpack(l, selfBox, children)
    }

}
