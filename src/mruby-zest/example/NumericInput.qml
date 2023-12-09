Widget {
    id: numeric
    property Object valueRef: nil
    property Symbol style: :normal
    property Function whenValue: nil
    property Float  value: 0


    
    
    
    function onSetup(old=nil)
    {
        @last = Time.new
        
    #~ (0...8).each do |f|
        #~ widget = Qml::TextField.new(numeric.db)
        #~ widget.w = 10
        #~ widget.h = 40
        #~ widget.x = 10*f
        #~ widget.y = 0
        #~ widget.layer = 2
        #~ widget.label = numeric.label[f]
        #~ Qml::add_child(numeric, widget)
    #~ end
        
        
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

        vg.text(8,h/2,l)
        bnd = vg.text_bounds(0,0,l)
        if(@state)
            vg.text(8+bnd,h/2,"|")
        end
    }
    
    
    function handleScroll(x, y, ev)
    {
        #puts "x #{x.to_s}"
        #puts "y #{y.to_s}"       
        glb_x = parent.global_x + self.x
        glb_y = parent.global_y + self.y + self.h/2
        dx = x - glb_x
        dy = y - glb_y

        if (y > parent.global_y + self.y && y < parent.global_y + self.y + self.h )
            #~ puts "ev.dy #{ev.dy.to_s}"
            #~ puts "dx #{dx.to_s}"
            #~ puts "dy #{dy.to_s}"
            ind = (((dx - 10) / 13)).floor
            ind = 0 if (ind < 0)
            
            ind_colon = label.index('.')
            #~ puts "ind #{ind.to_s}"
            #~ puts "ind_colon #{ind_colon.to_s}"
            if (ind_colon)
                if (ind<ind_colon) 
                    exponent = ind_colon-ind-1
                elsif (ind>ind_colon) 
                    exponent = ind_colon-ind
                end
                #~ puts "exponent #{exponent.to_s}"
                
            else
                exponent = label[/\A\d*/].length - ind -1
                #~ puts "exponent #{exponent.to_s}"
                
            end
            increment = (10 ** exponent)*ev.dy
            #~ puts "increment #{increment.to_s}"
            value = self.label.to_f
            value = value + increment
            $remote.setf(self.parent.extern, value)
            self.label = value.to_s
            self.damage_self
            
            
        end    
    
    }
    function onKey(k, mode)
    {
        return if mode != "press"
        #puts("onKey #{k.inspect}")
        if(k.ord == 27) #esc
            self.label = ""
            whenEnter
            return
        elsif(k.ord == 13) #enter
            whenEnter
            return
        elsif(k.ord == 8)
            self.label = self.label[0...-1] if !self.label.empty?
            self.damage_self
            return
        elsif k.ord >= 32
            self.label += k
            self.damage_self
            return
        end
        damage_self
    }

    function whenEnter() {
        #puts "WhenEnter..."
        if whenValue then
            whenValue.call 
        else
            self.root.ego_death self
        end
        #valueRef.value = self.label if valueRef
        #damage_self

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
