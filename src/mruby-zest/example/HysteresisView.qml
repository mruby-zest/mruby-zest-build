Widget {
    id: hyst_view
    property Bool   grid: true;
    property Bool   draw_borders: false
    property Object valueRef: nil
    property Float pad: 1.0/32
    function class_name() { "HysteresisView" }

    onExtern: {
        data = OSC::RemoteParam.new($remote, hyst_view.extern)
        data.callback = lambda {|x|
            hystdata_view.data = x
            hystdata_view.damage_self
        }

        hyst_view.valueRef = [data]
        
    }

    HystDataView {
        id: hystdata_view
    }

    function draw(vg)
    {
        pad2 = (1-2*pad)
        box = Rect.new(w*pad, h*pad, w*pad2, h*pad2)
        background Theme::VisualBackground

        if(grid)
            Draw::Grid::linear_x(vg,0,10,box, 1.0)
            Draw::Grid::linear_y(vg,0,10,box, 1.0)
        end

        if(draw_borders)
            vg.translate(0.5, 0.5)
            vg.path do |v|
                v.stroke_width = 1
                v.stroke_color = Theme::GridLine
                v.rounded_rect(box.x.round(), box.y.round(), box.w.round(), box.h.round(), 2)
                v.stroke()
            end
            vg.translate(-0.5, -0.5)
        end

        if(extern.nil? || extern.empty?)
            Draw::WaveForm::sin(vg, box, 128)
        end
    }

    function refresh()
    {
        return if self.valueRef.nil?
        self.valueRef.each do |v|
            v.refresh
        end
    }
}
