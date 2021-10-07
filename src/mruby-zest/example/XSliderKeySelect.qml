Valuator {
    property Bool centered: false;
    property Float pad: 0.02
    property Float height: 0.6
    property Bool  active: true
    property Bool  value_label: false
    vertical: false

    function draw_centered(vg, pad)
    {
        pad2 = (1-2*pad)
        va = 1-value
        if(va >= 0.5)
            vv   = [0.01, va-0.5+0.01].max
            src = (w*0.5-w*pad2*vv)
            dst = (w*0.51)
            vg.path do |v|
                v.rect(src, pad*h, (src-dst).abs, pad2*h)
                v.fill_color Theme::SliderActive
                v.fill
            end
        else
            vv   = [0.01, 0.5-va+0.01].max
            vg.path do |v|
                v.rect(w*0.49, pad*h, pad2*w*vv, pad2*h)
                v.fill_color Theme::SliderActive
                v.fill
            end
        end
    }

    function getkeystring()
    {
        mval=self.valueRef.display_value
        cval = -1+mval.to_i/12
        eval = mval.to_i%12
        oval="C"if (eval==0)
        oval="C#" if (eval==1) 
        oval="D" if (eval==2) 
        oval="D#" if (eval==3) 
        oval="E" if (eval==4) 
        oval="F" if (eval==5) 
        oval="F#" if (eval==6) 
        oval="G" if (eval==7) 
        oval="G#" if (eval==8) 
        oval="A" if (eval==9) 
        oval="A#" if (eval==10) 
        oval="B" if (eval==11) 
        dval=oval.to_s + cval.to_s + " (" + mval.to_s + ")"
        return dval 
    }

    function draw(vg)
    {
        self.dragScale = w
        pad2 = (1-2*pad)
        vg.path do |v|
            v.rect(pad*w, pad*h, pad2*w, pad2*h)
            v.fill_color Theme::SliderBackground
            v.stroke_color color(:black)
            v.fill
            v.stroke
        end

        if(centered)
            draw_centered(vg, pad)
        else
            vg.path do |v|
                v.rect(pad*w, pad*h, value*w*pad2, pad2*h)
                v.fill_color Theme::SliderActive
                v.fill
            end
        end

        vg.path do |v|
            v.move_to(w*pad+w*pad2*value, pad*h)
            v.line_to(w*pad+w*pad2*value, pad2*h)
            v.stroke_color Theme::SliderStroke
            v.stroke_width 2.0
            v.stroke
        end

        vg.font_face("bold")
        vg.font_size 4+height*h
        vg.text_align NVG::ALIGN_CENTER | NVG::ALIGN_MIDDLE
        vg.fill_color(Draw::fade(Theme::TextColor))
        if(value_label && self.valueRef)
            vg.text(w/2,h/2, getkeystring())
        else
            vg.text(w/2,h/2,label.upcase)
        end


        if(!self.active)
            vg.path do
                vg.move_to(pad*w, pad*h)
                vg.line_to(pad2*w, pad2*h)
                vg.stroke_color Theme::SliderStroke
                vg.stroke
            end
        end
    }
}
