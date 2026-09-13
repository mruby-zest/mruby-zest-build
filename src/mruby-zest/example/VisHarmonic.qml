Widget {
    id: hm
    property Float pad: 1.0/32
    property Object valueRef: nil
    property Array  points:   nil
    property Bool   needRefresh: false

    onExtern: {
        hm.valueRef = OSC::RemoteParam.new($remote, hm.extern)
        hm.valueRef.callback = Proc.new {|x| hm.setValue(x)}
    }

    function setValue(x)
    {
        if(x != self.points)
            self.points = x
            damage_self
        end
    }

    function animate()
    {
        if(self.valueRef && self.needRefresh)
            self.needRefresh = false
            self.valueRef.refresh
        end
    }

    function refresh()
    {
        self.needRefresh = true
    }

    function draw(vg)
    {
        pad2 = (1-2*pad)
        box = Rect.new(w*pad, h*pad, w*pad2, h*pad2)

        background Theme::VisualBackground

        Draw::Grid::linear_x(vg,0,10,box, 1.0)
        Draw::Grid::linear_y(vg,0,10,box, 1.0)

        xpoints = Draw::DSP::linspace(-2,2,128)
        ypoints = nil
        vline   = 0.15
        if(self.points)
            ypoints = self.points[1..-1].map {|x| 2*x-1}
            vline   = self.points[0]/2
        else
            ypoints = xpoints.map {|x| 2*Math.exp(-x**2/0.1)-1 }
        end

        ypoints = ypoints.map {|x| if x < -0.9925 then -0.9925 else x end}

        paint = vg.linear_gradient(0.5*w-vline*w, h*pad2 - h*pad, 0.5*w-vline*w, h*pad, Theme::HighlightGrad1, Theme::HighlightGrad2)

        # Rectangle between the vertical lines
        vg.path do |v|
            v.rect(0.5*w-vline*w, h*pad, 2*vline*w, h*pad2)
            v.fill_paint paint
            v.fill
        end

        # Plot
        Draw::WaveForm::plot(vg, ypoints, box, true, 0, 1)

        # Vertical lines
        vg.path do |v|
            v.translate(0.5, 0.5)
            v.move_to((0.5*w+vline*w).round(), box.y)
            v.line_to((0.5*w+vline*w).round(), box.y + box.h - 2)
            v.move_to((0.5*w-vline*w).round(), box.y)
            v.line_to((0.5*w-vline*w).round(), box.y + box.h - 2)
            v.stroke_color Theme::HarmonicColor
            v.stroke_width 1
            v.stroke
            v.line_cap(NVG::SQUARE);
            v.translate(-0.5, -0.5)
        end
    }
}
