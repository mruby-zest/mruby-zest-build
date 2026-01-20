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

        @edit ||= EditRegion.new($vg, self.label, w-20, h*0.8)
        @edit.each_string do |x, y, str, cursor|
            if(cursor == false)
                vg.text(x+10, y, str)
            else
                if(@state)
                    vg.text_align NVG::ALIGN_LEFT| NVG::ALIGN_MIDDLE
                    vg.text(x+10, y, str)
                end
            end
        end

    }

    function onKey(k, mode)
    {
        return if mode != "press"
        pos = self.label.length
        pos = @edit.pos if @edit
        ll = self.label

        cursorrow = @edit.cursor_row

        if(k.ord == 8)
            pos -= 1
            if(pos >= ll.length)
                self.label = ll[0...-1]
            elsif(pos >= 0)
                self.label = ll.slice(0, pos+cursorrow) + ll.slice(pos+1+cursorrow, ll.length)
            end
        else
            self.label = ll.insert(pos+cursorrow, k)
        end
        ll = self.label
        whenValue.call if whenValue
        valueRef.value = self.label if valueRef
        @edit     = EditRegion.new($vg, ll, w-20, 0.8*h)
        if(k.ord == 8)
            @edit.pos = pos
        else
            @edit.pos = pos+1
        end
        damage_self
    }

    
    function onSpecial(k, mode)
    {
        return if @edit.nil?
        return if mode != :press
        
        if(k == :left)
            @edit.left
        elsif(k == :right)
            @edit.right
        end
        
        @state = true
        now = Time.new
        @next = now + 0.7
        damage_self
    }

    function onMerge(val)
    {
        self.label = val.label
    }
}