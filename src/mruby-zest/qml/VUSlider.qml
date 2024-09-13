Valuator {
    id: vuslider

    property Float pad: 0.1
    property Bool  visual:   false

    function class_name()
    {
        "VUSlider"
    }

    function rap2dB(x) { 20*Math::log10(x) }
    function lowerbound(x)  { [1.25,[0.0, x].max].min }
    function cv(x)     {min_db = -40;lowerbound((min_db-rap2dB(x))/min_db)}

    function draw_normal(vg)
    {
        col  = Theme::SliderActive
        col  = Theme::SliderVisActive if visual
        pad2 = (h-2*pad)

        # Colors for clipping indicator
        yellow_color = color("FFCC00")  # Yellow
        red_color = color("FF0000")     # Red

        total_height = (pad2 * 0.8*value).round()
        total_start = pad2 - total_height
        yellow_val = 0.8 * cv(0.316);
        yellow_height = yellow_val * pad2 # -10dB
        yellow_start = (1-yellow_val)*pad2
        red_val = 0.8 * cv(1)
        red_height = (red_val * pad2) # 0 dB
        red_start = (1-red_val)*pad2

        vu_width = (w)
        if vu_width > 1
            vu_width = vu_width.round()
        end


        if total_height < yellow_height
            vg.path do |v|
                v.rect(pad,total_start, vu_width, total_height)
                v.fill_color col
                v.fill
            end

        elsif total_height < red_height
            vg.path do |v|
                v.rect(pad,yellow_start, vu_width, yellow_height)
                v.fill_color col
                v.fill
            end
            vg.path do |v|
                v.rect(pad,total_start, vu_width, total_height-yellow_height)
                v.fill_color yellow_color
                v.fill
            end

        elsif total_height >= red_height
            vg.path do |v|
                v.rect(pad,yellow_start, vu_width, yellow_height)
                v.fill_color col
                v.fill
            end
            vg.path do |v|
                v.rect(pad,red_start, vu_width, red_height-yellow_height)
                v.fill_color yellow_color
                v.fill
            end
            vg.path do |v|
                v.rect(pad,total_start, vu_width, total_height - red_height)
                v.fill_color red_color
                v.fill
            end
        end

    }

    function draw(vg)
    {
        self.dragScale = h
        pad2 = (1-2*pad)
        vg.path do |v|
            v.rect(pad*w, pad*h, pad2*w, pad2*h)
            v.fill_color Theme::SliderBackground
            v.fill
        end

        vg.path do |v|
            v.move_to(pad* w, pad* h)
            v.line_to(pad* w, pad2*h)
            v.move_to(pad2*w, pad* h)
            v.line_to(pad2*w, pad2*h)
            v.stroke_color color(:black)
            v.stroke
        end

        return if value.class != Float

        draw_normal(vg)

        vg.path do |v|
            yloc = (h-((h-2*pad)*value* 0.8))
            v.move_to(w*pad,  yloc)
            v.line_to(w*pad2, yloc)
            v.stroke_color Theme::SliderStroke
            v.stroke_width 2.0
            v.stroke
        end
    }

    function onScroll(ev) {
        super(ev) if !visual
    }

    function onMousePress(ev) {
        mouse_handle(ev) if !visual
    }
}

