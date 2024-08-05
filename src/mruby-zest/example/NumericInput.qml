Widget {
    id: numeric
    property Object valueRef: nil
    property Symbol style: :normal
    property Function whenValue: nil
    property Float  value: 0
    property bool first: true
    
    function onSetup(old=nil)
    {
        @last = Time.new
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
        if(self.style == :overlay)
            draw_overlay(vg)
        else
            draw_normal(vg)
        end

    }

    function draw_overlay(vg)
    {
        background color("1b1c1c")
        vg.font_face("bold")
        vg.font_size h*0.8
        vg.text_align NVG::ALIGN_LEFT | NVG::ALIGN_MIDDLE
        vg.fill_color = color("56c0a5")
        l = "..."
        if(label.class == String && !label.empty?)
            l = label.clone
        elsif(label.class == Array)
            l = label[0].clone
        end

        (0...l.length).each do |i|
            l[i] = "?" if l.getbyte(i) > 127
        end

        bnd = vg.text_bounds(0,0,l+"|")
        if(bnd+8 > self.w)
            vg.font_size self.h*self.w/(bnd+8)*0.8
            bnd = vg.text_bounds(0,0,l)
        end

        vg.text(8,h/2,l)
        if(@state)
            vg.text(8+bnd,h/2,"|")
        end
    }
    function draw_normal(vg)
    {
        background Theme::GeneralBackground
        vg.font_face("bold")
        vg.font_size h*0.8
        vg.text_align NVG::ALIGN_LEFT | NVG::ALIGN_MIDDLE
        vg.fill_color = Theme::TextColor
        l = label.empty? ? "..." : label.clone

        (0...l.length).each do |i|
            l[i] = "?" if l.getbyte(i) > 127
        end
        
        vg.path do
            vg.rect(1, 1, w-2, h-2)
            vg.stroke_color  color("3AC5EC")
            vg.stroke_width 1.0
            vg.stroke
        end

        vg.text(8,h/2,l)
        bnd = vg.text_bounds(0,0,l)
        if(@state)
            vg.text(8+bnd,h/2,"|")
        end
    }
    
    
    function handleScroll(x, y, ev)
    {
    
        glb_x = parent.global_x + self.x
        glb_y = parent.global_y + self.y + self.h/2
        dx = x - glb_x
        dy = y - glb_y

        if (y > parent.global_y + self.y && y < parent.global_y + self.y + self.h )

            ind = (((dx - 10) / 13)).floor
            ind = 0 if (ind < 0)
            
            ind_colon = label.index('.')

            if (ind_colon)
                if (ind<ind_colon) 
                    exponent = ind_colon-ind-1
                elsif (ind>ind_colon) 
                    exponent = ind_colon-ind
                end
                
            else
                exponent = label[/\A\d*/].length - ind -1
                exponent = 0 if(exponent < 0)
            end
            increment = (10 ** exponent)*ev.dy
            if self.parent.type
                value = self.label.to_f
            else
                value = self.label.to_i
            end
            
            value = value + increment
            
            $remote.setf(self.parent.extern, value) if(parent.valueRef)
            parent.whenValue.call if parent.whenValue
            parent.damage_self
            self.label = value.to_s
            self.damage_self
            self.first = false
            
        end    
    
    }
    
    function remove_decimal_places(numeric_string)
    {
        # Verwende split, um den String am Dezimalpunkt '.' oder ',' zu trennen
        if numeric_string.include?('.')
            integer_part = numeric_string.split('.').first + '.'
            self.first = false
        elsif numeric_string.include?(',')
            integer_part = numeric_string.split(',').first + ','
            self.first = false
        else
            integer_part = numeric_string
        end
        # Gib den ganzzahligen Teil des Strings zurück
        self.label = integer_part
    }
    
    
    function onKey(k, mode)
    {
        return if mode != "press"
        if(k.ord == 27) #esc
            self.label = ""
            whenEnter
            return
        elsif(k.ord == 13) #enter
            whenEnter
            return
        elsif(k.ord == 8) #backspace

            self.label = self.label[0...-1] if !self.label.empty?
            self.damage_self
            self.first = false
            return
        elsif  (k.ord >= 48 && k.ord <= 57) ||    # Main Numbers  0 ... 9
               (k.ord >= 96 && k.ord <= 105) ||   # NumPad Numbers 0 ... 9
               (k.ord >= 43 && k.ord <= 46)       # NumPad-Komma , + -

            if (self.first)
                if k == ',' or k == '.'
                    remove_decimal_places(self.label)
                else
                    self.label = ""
                    self.first = false
                    self.label = self.label + k
                end
            else 
                self.label = self.label + k if k != '-' and k != '+' # '-' only at the beginning
                self.label = k + self.label if k == '-' and self.label[0] != '-' and self.label[0] != '+' # negate
                self.label[0] = '+' if k == '+' and self.label[0] == '-' # un-negate
                self.label[0] = '-' if k == '-' and self.label[0] == '+' # re-negate
                
            end

            self.damage_self
            return
        end
        damage_self
    }

    function whenEnter() {
        if whenValue then
            whenValue.call 
        else
            self.root.ego_death self
        end

    }

    function onMousePress(m)
    {
        now = Time.new
        @last ||= now
        whenEnter if((now-@last)>0.05)
    }



    function onMerge(val)
    {
        self.label = val.label
    }

    onExtern: {
        ref = OSC::RemoteParam.new($remote, numeric.extern)
        ref.callback = lambda {|x|
            numeric.label = x;
            numeric.damage_self
        }
        numeric.valueRef = ref
    }
}
