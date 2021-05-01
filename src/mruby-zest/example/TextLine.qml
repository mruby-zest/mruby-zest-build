Widget {
    id: textedit
    property Function whenValue: nil
    property Object   valueRef:  nil
    property Bool     upcase:    true
    // TODO: this property is not used by any calling code. Delete?
    property String   ext:       nil

    onExtern: {
        ref = OSC::RemoteParam.new($remote, textedit.extern)
        ref.callback = lambda {|x|
            textedit.label = x;
            textedit.damage_self
        }
        textedit.valueRef = ref
    }

    function animate()
    {
        if(root.key_widget != self)
            @next = nil
            if(@state)
                @state = nil
                damage_self
            end
            return
        end
        now = Time.new
        if(@next.nil?)
            @next = now + 0.1
            return
        elsif(@next < now)
            @state = !@state
            @next = now + 0.7
            damage_self
        end
    }

    function draw(vg)
    {
        background Theme::GeneralBackground
        vg.font_face("bold")
        vg.font_size h*0.8
        vg.text_align NVG::ALIGN_LEFT | NVG::ALIGN_MIDDLE
        vg.fill_color = Theme::TextColor

        l = label.empty? ? "..." : label.clone
        l = l+self.ext if self.ext && !l.end_with?(self.ext)
        l = l.upcase if self.upcase
        (0...l.length).each do |i|
            l[i] = "?" if l.getbyte(i) > 127
        end
        vg.text(8,h/2,l)
        bnd = vg.text_bounds(0,0,l)
        if(@state)
            vg.text(8+bnd,h/2,"|")
        end
    }

    function onKey(k, mode)
    {
        return if mode != "press"
        if(k.ord == 8)
            self.label = self.label[0...-1]
        elsif k.ord >= 32
            self.label += k
        end
        whenValue.call if whenValue
        valueRef.value = self.label if valueRef
        damage_self
    }

    function onMerge(val)
    {
        self.label = val.label
    }
}
