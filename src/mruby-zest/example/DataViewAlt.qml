Widget {
    id: draw_alt
    layer: 1
    property Array points: draw_alt.mk_points

    function mk_points()
    {
        pts = []
        while(pts.length < 256)
            pts << 0
        end
        pts
    }

    function draw(vg)
    {
        fill_color    = Theme::VisualBackground
        stroke_color  = Theme::VisualStroke
        dim           = Theme::VisualDim

        padfactor = 12
        bb = Draw::indent(Rect.new(0,0,w,h), padfactor, padfactor)

        background(fill_color)

        #Draw borders of the envelope display
        vg.translate(0.5, 0.5)
        vg.path do |v|
            v.stroke_width = 1
            v.stroke_color = Theme::GridLine
            v.rounded_rect(bb.x.round(), bb.y.round(), bb.w.round(), bb.h.round(), 2)
            v.stroke()
        end
        vg.translate(-0.5, -0.5)

        #Draw Zero Line
        Draw::WaveForm::zero_line(vg, bb, dim)

        Draw::WaveForm::plot(vg, self.points, bb, false, 0, Draw::PlotHighlight::BIDIRECTIONAL)
    }
}
