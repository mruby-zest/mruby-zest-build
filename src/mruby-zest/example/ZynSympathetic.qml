Widget {
    id: sym

    property Object valueRef: nil

    function refresh_recur(x) {
        #@@recur_level ||= 0
        #@@recur_level += 1
        #print " "*@@recur_level
        #puts "Distort refresh = {#{x.class}} of {#{dst.class}}"
        x.children.each do |xx|
            #print " "*(@@recur_level+1)
            #puts "child = #{xx.class}"
            xx.refresh() if xx.respond_to? :refresh
            sym.refresh_recur(xx)
        end
        #@@recur_level -= 1
    }
    function refresh() {
        refresh_recur(self)
    }

    GroupHeader {
        label: "Sympathetic"
        extern: sym.extern
        copyable: true
    }

    ParModuleRow {
            Selector {
            extern: sym.extern + "Sympathetic/preset"
            whenValue: lambda { sym.refresh }
        }
        Knob { extern: sym.extern + "Pvolume"}
        Knob { extern: sym.extern + "Ppanning"}
        Knob { extern: sym.extern + "Sympathetic/Pdrive"}
        Knob { extern: sym.extern + "Sympathetic/Plevel"}
        Knob { extern: sym.extern + "Sympathetic/Pstrings"}
        Knob { extern: sym.extern + "Sympathetic/Pq"}
        Knob { extern: sym.extern + "Sympathetic/Punison_size"}
        Knob { extern: sym.extern + "Sympathetic/Punison_frequency_spread"}
        Knob { extern: sym.extern + "Sympathetic/Pbasenote"}
        Knob { extern: sym.extern + "Sympathetic/Plpf"}
        Knob { extern: sym.extern + "Sympathetic/Phpf"}
    }

    function draw(vg) {
        Draw::GradBox(vg, Rect.new(0, 0, w, h))
    }

    function layout(l, selfBox) {
        Draw::Layout::vfill(l, selfBox, children, [0.15,0.85])
    }

    function onSetup(old=nil)
    {}
}
