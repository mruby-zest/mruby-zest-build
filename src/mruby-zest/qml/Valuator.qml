Widget {
    id: valuator
    property Object valueRef: nil;
    property Object prev:     nil;

    property Float value: 1.0;     // Current value in [0,1]. If logmin is set: either 0 or in [0.07,1].
    property Float unclValue: 1.0; // Current value in [0,1], unclipped

    property Float dragScale: 200.0;
    property Bool  vertical: true

    property Function whenValue: nil;

    property Bool active: true

    property Symbol type: nil

    property String units: nil

    onExtern: {
        meta = OSC::RemoteMetadata.new($remote, valuator.extern)
        valuator.label   = meta.short_name if valuator.label == ""
        valuator.tooltip = meta.tooltip
        valuator.units   = meta.units

        valuator.valueRef = OSC::RemoteParam.new($remote, valuator.extern)
        valuator.valueRef.set_min(meta.min)
        valuator.valueRef.set_max(meta.max)
        valuator.valueRef.set_logmin(meta.logmin)
        valuator.valueRef.set_scale(meta.scale)
        valuator.valueRef.type     = "f" if valuator.type
        valuator.valueRef.callback = Proc.new {|x| valuator.setValue(x)}

    }

    function numeric_input()
    {

        widget = Qml::NumericInput.new(valuator.db)
        widget.w = (self.type) ? 160 : 80 
        widget.h = 40
        widget.x = (valuator.w-widget.w)/2
        widget.y = -valuator.h/2
        widget.layer = 2
        if(self.type)
            value = valuator.valueRef.display_value.round(5) 
        else
            value = valuator.valueRef.display_value
        end
        widget.label = value.to_s
        widget.whenValue = lambda {

            root.set_modal(nil)
            old_dsp = valuator.valueRef.display_value
            numericString = widget.label.gsub(',', '.')
            return if numericString == "-" or numericString == "." or numericString == "+"
            if(valuator.valueRef)
                $remote.setf(self.extern, numericString.to_f) if self.type and !(widget.label.empty?)
                $remote.seti(self.extern, numericString.to_i) if !self.type and !(widget.label.empty?)
                new_dsp = valuator.valueRef.display_value
                whenValue.call if whenValue && (new_dsp.nil? || old_dsp != new_dsp)
                out_value = displayValueToText(valuator.valueRef.display_value)
                valuator.root.log(:user_value, out_value, src=valuator.label)
            else
                whenValue.call if whenValue
            end
            damage_self

        }
        root.set_modal(widget)
        Qml::add_child(valuator, widget)
        valuator.root.smash_draw_seq
        valuator.root.damage_item widget
    }


    //Callback function which does not propagate info to remote API
    function setValue(v) {
        if(valuator.valueRef.has_logmin() && v > 0.0 && v < 0.07)
            v = (v < 0.035) ? 0 : 0.07
        end
        self.value = self.unclValue = lim(v, 0.0, 1.0)
        damage_self
    }

    function refresh() { valueRef.refresh if valueRef }

    function create_radial()
    {
        return
        gbl_cx = valuator.global_x + 0.5*valuator.w
        gbl_cy = valuator.global_y + 0.5*valuator.h
        gbl_w  = window.w
        gbl_h  = window.h

        ropt = [gbl_cx, gbl_cy, gbl_w-gbl_cx, gbl_h-gbl_cy].min

        diameter = [2.0*ropt, 3.0*0.5*(valuator.w+valuator.h)].min

        widget = Qml::RadialMenu.new(valuator.db)
        widget.w = diameter
        widget.h = diameter
        widget.x = valuator.w/2-diameter/2
        widget.y = valuator.h/2-diameter/2
        widget.layer = 2
        widget.callback = lambda {|sel|
            case sel
            when 0
                valueRef.midi_learn if valueRef
            when 1
                valueRef.rand if valueRef
            when 2
                valueRef.midi_unlearn if valueRef
            when 3
                valueRef.default if valueRef
            end
        }

        Qml::add_child(valuator, widget)
        valuator.root.smash_draw_seq
        valuator.root.damage_item widget
    }

    function onScroll(ev)
    {
        return if !self.active
        fine = root.fine_mode ? 0.2 : 1.0
        updatePos(-fine*ev.dy/50.0)
    }

    function reset() {
        reset_value = 64.01/127.0
        self.value = self.unclValue = reset_value
        if(valueRef)
            old_dsp = self.valueRef.display_value

            self.valueRef.value = reset_value
            new_dsp = self.valueRef.display_value
            whenValue.call if whenValue && (new_dsp.nil? || old_dsp != new_dsp)
            valuator.root.log(:user_value, valuator.valueRef.display_value, src=valuator.label)
        end
        damage_self
    }

    function onMousePress(ev) {
        mouse_handle(ev)
    }

    function mouse_handle(ev) {
        return if !self.active
        if(root.learn_mode && extern)
            $remote.automate(extern)
            root.log(:tooltip, "Learning #{extern}")
        end
        if(ev.buttons.include? :leftButton)
            valuator.prev = ev.pos
            now = Time.new
            #400 ms delta for double click
            if(@click_time && (now-@click_time) < 0.400)
                $remote.default(extern) if extern
                whenValue.call if whenValue
                if (valuator.valueRef)
                    dsp = displayValueToText(valuator.valueRef.display_value)
                    self.root.log(:tooltip, dsp)
                end
            end
            @click_time = now
        elsif(ev.buttons.include? :rightButton)
            if(children.empty?)
                #create_radial
                numeric_input()
            end
        elsif(ev.buttons.include? :middleButton)
            reset
        elsif(ev.buttons.include? :drag_and_drop)
            puts "sending dnd event..."
            $remote.action("/last_dnd", self.extern)
        else
            valuator.prev = nil
        end
    }

    function onMouseMove(ev) {
        return if !self.active
        fine = root.fine_mode ? 0.05 : 1.0
        if(prev)
            delta = if(vertical)
                +(ev.pos.y - self.prev.y)
            else
                -(ev.pos.x - self.prev.x)
            end
            updatePos(fine*delta/dragScale)
            self.prev = ev.pos
        end
    }

    function onMouseEnter(ev) {
        dsp = self.tooltip
        if (valuator.valueRef)
            dsp = displayValueToText(valuator.valueRef.display_value) + "   " +
              dsp
        end
        self.root.log(:tooltip, dsp)
    }

    function lim(x, low, high)
    {
        [low, [x, high].min].max
    }

    function displayValueToText(dval) {
        if (dval.class == Float)
            tval = dval.round(2)
        else
            tval = dval
        end
        tval = tval.to_s
        if(valuator.units && valuator.units != "none")
            tval += " "
            tval += valuator.units
        end
        return tval
    }

    function updatePosAbs(tmp) {
        nvalue = lim(tmp, 0.0, 1.0)
        valuator.unclValue = nvalue
        if(valuator.valueRef &&
           valuator.valueRef.has_logmin() && nvalue > 0.0 && nvalue < 0.07)
            nvalue = (nvalue < 0.035) ? 0 : 0.07
        end
        valuator.value = nvalue
        if(valuator.valueRef)
            old_dsp = valuator.valueRef.display_value
            valuator.valueRef.value = nvalue
            new_dsp = valuator.valueRef.display_value
            whenValue.call if whenValue && (new_dsp.nil? || old_dsp != new_dsp)
            out_value = displayValueToText(valuator.valueRef.display_value)
            valuator.root.log(:user_value, out_value, src=valuator.label)
        else
            whenValue.call if whenValue
        end
        damage_self
    }

    function updatePos(delta) {
        updatePosAbs(valuator.unclValue - delta)
    }

    function onMerge(val)
    {
        return if self.class != val.class
        valuator.value = val.value if(val.respond_to?(:value))
        valuator.unclValue = val.unclValue if(val.respond_to?(:unclValue))
    }

}
