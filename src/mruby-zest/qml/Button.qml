Widget {
    id: button
    property signal   action: nil;
    property Bool     value:    false;
    property String   renderer: nil;
    property Float    textScale: 0.75;
    property Function whenValue: nil;
    property Float    pad: 1.0/64
    property Bool     active: true
    property Bool     rocker: false

    function onMousePress(ev) {
        return if !self.active
        button.value = !button.value
        damage_self
        whenValue.call if whenValue
    }

    function onMerge(val)
    {
        button.value = val.value if(val.respond_to? :value)
    }

    function class_name()
    {
        "Button"
    }

    function aspect2(box, ww, hh)
    {
        provided    = box.w/box.h
        recommended = ww/hh
        if(recommended > provided)
            #Decrease height
            new_height = box.h*provided/recommended
            box.y += (box.h-new_height)/2
            box.h = new_height
        else
            new_width = box.w*recommended/provided
            box.x += (box.w-new_width)/2
            box.w  = new_width
        end
    }


    function layout(l, selfBox)
    {
        if(!self.layoutOpts.include?(:no_constraint))
            if(label.length == 1)
                l.aspect(selfBox, 1, 1)
            else
                scale = 100
                $vg.font_size scale
                bb = $vg.text_bounds(0, 0, label.upcase)
                if(bb != 0)
                    #Width cannot be so small that letters overflow
                    self.aspect2(selfBox, bb, scale)
                end
            end
        end
        selfBox
    }

    function draw_text(vg)
    {
        text_color1   = Theme::TextActiveColor
        text_color2   = Theme::TextColor
        vg.font_face("bold")
        vg.font_size h*self.textScale
        if(button.rocker)
            # Expects label to be of the form "lin/log", where the left
            # portion represents the 'true' value of the underlying parameter.
            texts = label.split("/")
            text = texts[0]
        else
            text = label
        end
        # While it initially looks redundant to test against 'true', remember
        # that 'value' is a float when the Button is a TriggerButton. If we
        # don't check against true here, the button text while change to the
        # 'enabled' color (light blue) when clicking a TriggerButton, and
        # remain in that color, rather than just staying light grey.
        if(value == true)
            vg.fill_color(text_color1)
        else
            vg.fill_color(text_color2)
        end
        if(layoutOpts.include? :left_text)
            vg.text_align NVG::ALIGN_LEFT | NVG::ALIGN_MIDDLE
            vg.text(8,h/2,text.upcase)
        else
            vg.text_align NVG::ALIGN_CENTER | NVG::ALIGN_MIDDLE
            if(button.rocker)
                vg.text(w/4,h/2,text.upcase)
            else
                vg.text(w/2,h/2,text.upcase)
            end
        end
        if (button.rocker)
            # Right hand side of rocker button
            # We use -1 so we always get the last element regardless of if
            # the array actually contains 2 elements
            text = texts[-1]
            if(value == true)
                vg.fill_color(text_color2)
            else
                vg.fill_color(text_color1)
            end
            if(layoutOpts.include? :left_text)
                # Since the left button half aligns left, we align the
                # right hand one to the right, for symmetry.
                vg.text_align NVG::ALIGN_RIGHT | NVG::ALIGN_MIDDLE
                vg.text(w-9,h/2,text.upcase)
            else
                vg.text_align NVG::ALIGN_CENTER | NVG::ALIGN_MIDDLE
                vg.text(w*3/4-2,h/2,text.upcase)
            end
        end
    }

    function draw_inactive(vg)
    {
        strike_color = Theme::TextColor
        vg.path do
            vg.move_to(w*pad, h*pad)
            vg.line_to(w*(1-2*pad), h*(1-2*pad))
            vg.stroke_width 1.0
            vg.stroke_color strike_color
            vg.stroke
        end
    }

    function draw_button(vg)
    {
        off_color     = Theme::ButtonInactive
        on_color      = Theme::ButtonActive
        cs = 0
        vg.path do |v|
            # Whole button, or left part of button for rocker
            if(button.rocker)
                r = w*(1-2*pad)*0.5
            else
                r = w*(1-2*pad)
            end
            v.rounded_rect(w*pad, h*pad, r, h*(1-2*pad), 2)
            # Although the test against 'true' might seem redundant, it's
            # needed because 'value' will be a float when the Button is a
            # TriggerButton, and we purposely want to check for a boolean
            # false here.
            if(button.value == true)
                cs = 1
                v.fill_color on_color
            elsif(button.value.class == Float && button.value != 0)
                cs = 2
                t = button.value
                on = on_color
                of = Theme::ButtonGrad1
                v.fill_color(color_rgb(on.r*t + of.r*(1-t),
                                       on.g*t + of.g*(1-t),
                                       on.b*t + of.b*(1-t)))
            else
                paint = v.linear_gradient(0,0,0,h,
                Theme::ButtonGrad1, Theme::ButtonGrad2)
                v.fill_paint paint
            end
            v.fill
            v.stroke_width 1
            v.stroke
        end

        if(button.rocker)
            # Right part of rocker button
            vg.path do |v|
                v.rounded_rect(w*(1-2*pad)*0.5, h*pad, w*(1-2*pad)*0.5, h*(1-2*pad), 2)
                # Rocker buttons are never used as TriggerButtons, so can
                # always assume 'value' is a boolean value here.
                if(button.value)
                    paint = v.linear_gradient(0,0,0,h,
                    Theme::ButtonGrad1, Theme::ButtonGrad2)
                    v.fill_paint paint
                else
                    v.fill_color on_color
                end
                v.fill
                v.stroke_width 1
                v.stroke
            end
        end

        vg.path do |v|
            # Little, slightly lighter horizontal field at top of button
            hh = h/20
            if([0,1].include?(cs))
                if(button.rocker)
                  r = w*(1-2*pad)*0.5-1
                else
                  r = w*(1-2*pad)+1
                end
                v.stroke_width hh

                v.move_to(w*pad+1,       h*pad+hh)
                v.line_to(r, h*pad+hh)
                if(cs == 0)
                    v.stroke_color color("5c5c5c")
                elsif(cs == 1)
                    v.stroke_color color("16a39c")
                end
                v.stroke

                if(button.rocker)
                    # Right part in rocker mode
                    vg.path do |v|
                        v.move_to(w*(1-2*pad)*0.5+1, h*pad+hh)
                        v.line_to(w*(1-2*pad)-1, h*pad+hh)
                        if(cs == 1)
                            v.stroke_color color("5c5c5c")
                        elsif(cs == 0)
                            v.stroke_color color("16a39c")
                        end
                        v.stroke
                    end
                end
            end

        end
    }


    function draw(vg)
    {
        draw_button(vg)

        draw_text(vg)

        draw_inactive(vg) if !self.active
    }
}
