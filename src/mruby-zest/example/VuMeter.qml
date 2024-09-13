Widget {
    id: meter
    property Object valueRef: nil
    property Object data: nil

    function animate() {
        self.valueRef.refresh if(self.valueRef)
    }

    function rap2dB(x) { 20*Math::log10(x) }
    function lowerbound(x)  { [1.25,[0.0, x].max].min }
    function cv(x)     {min_db = -40;lowerbound((min_db-rap2dB(x))/min_db)}

    function draw(vg)
    {
        indent_color = Theme::VisualBackground
        background indent_color

        bar_color = Theme::VisualLine
        pad  = 3
        pad2 = (h-2*pad)
        rms_l = 0.3
        rms_r = 0.3
        if(!data.nil?)
            rms_l = 0.8*cv(data[4])
            rms_r = 0.8*cv(data[5])
        end

        # Colors for clipping indicator
        yellow_color = color("FFCC00")  # Yellow
        red_color = color("FF0000")     # Red

        total_height = (rms_l)*(h-pad)
        total_start = (1-rms_l)*pad2
        yellow_height = (0.8*cv(0.316)) * (h-pad) # -10dB
        yellow_start = (1-0.8*cv(0.316))*pad2
        red_height = ((0.8*cv(1)) * (h-pad)) # 0 dB
        red_start = (1-0.8*cv(1))*pad2

        vu_width = (0.2*w)
        if vu_width > 1
            vu_width = vu_width.round()
        end


        if total_height < yellow_height
            vg.path do |v|
                v.rect(pad,total_start, vu_width, total_height)
                v.fill_color bar_color
                v.fill
            end
        elsif total_height < red_height
            vg.path do |v|
                v.rect(pad,yellow_start, vu_width, yellow_height)
                v.fill_color bar_color
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
                v.fill_color bar_color
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

        total_height = (rms_r)*(h-pad)
        total_start = (1-rms_r)*pad2

        if total_height < yellow_height
            vg.path do |v|
                v.rect(0.8*w-pad,total_start, vu_width, total_height)
                v.fill_color bar_color
                v.fill
            end
        elsif total_height < red_height
            vg.path do |v|
                v.rect(0.8*w-pad,yellow_start, vu_width, yellow_height)
                v.fill_color bar_color
                v.fill
            end
            vg.path do |v|
                v.rect(0.8*w-pad,total_start, vu_width, total_height-yellow_height)
                v.fill_color yellow_color
                v.fill
            end
        elsif total_height >= red_height
            vg.path do |v|
                v.rect(0.8*w-pad,yellow_start, vu_width, yellow_height)
                v.fill_color bar_color
                v.fill
            end
            vg.path do |v|
                v.rect(0.8*w-pad,red_start, vu_width, red_height-yellow_height)
                v.fill_color yellow_color
                v.fill
            end
            vg.path do |v|
                v.rect(0.8*w-pad,total_start, vu_width, total_height - red_height)
                v.fill_color red_color
                v.fill
            end
        end
    }

    function update_data(x)
    {
        if(self.data != x)
            self.data = x
            self.damage_self
        end
    }

    function onSetup(old=nil)
    {
        self.valueRef = OSC::RemoteParam.new($remote, "/vu-meter")
        self.valueRef.callback = lambda {|x| meter.update_data(x) }
        animate() if self.data
    }
}
