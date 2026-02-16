Widget {
    id: ovl

    function draw(vg)
    {
        return if self.class == Qml::HSlider and self.h < self.window.h / 160

        widget = Qml::NumericInput.new(valuator.db)
        widget.w = (self.type) ? 160 : 80
        widget.h = 40
        widget.w = valuator.w if self.class == Qml::HSlider
        widget.h = valuator.h if self.class == Qml::HSlider
        widget.x = (valuator.w-widget.w)/2
        widget.y = -valuator.h/2
        widget.y = (valuator.h-widget.h)/2 if self.class == Qml::HSlider
        widget.layer = 2
        return if not valuator.valueRef.respond_to?(:display_value)

        display_value = valuator.valueRef.display_value
        display_value ||= valuator.valueRef.default_value
        return if display_value.nil?

        if(self.type)
            value = display_value.round(5)
        else
            value = display_value
        end
        widget.label = value.to_s
        meta = OSC::RemoteMetadata.new($remote, self.extern)
        widget.min = meta.min
        widget.max = meta.max
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


        widget2 = Qml::ModulationOverlay.new(valuator.db)
        widget2.x = widget.x+widget.w
        widget2.y = widget.y+widget.h
        widget.layer = 2

        Qml::add_child(ovl, widget)
        Qml::add_child(ovl, widget2)

    }
}
