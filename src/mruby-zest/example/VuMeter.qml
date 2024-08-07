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
        v2 = 0.5
        if(!data.nil?)
            rms_l = 0.8*cv(data[4])
            v2 = 0.8*cv(data[5])
        end

        # Farben im gewünschten Format
        green_color = color("00FF55")  # Grün
        yellow_color = color("FFCC00")  # Gelb
        red_color = color("FF0000")  # Rot

        puts rms_l.inspect if rms_l>1
        total_height = (rms_l)*(h-pad)
        total_start = (1-rms_l)*pad2
        yellow_height = (0.8*cv(0.316)) * (h-pad) # -10dB
        yellow_start = (1-0.8*cv(0.316))*pad2
        red_height = ((0.8*cv(1)) * (h-pad)) # 0 dB
        red_start = (1-0.8*cv(1))*pad2
  
            
            
        if total_height < yellow_height
            vg.path do |v|
                v.rect(pad,total_start, 0.2*w, total_height)
                v.fill_color bar_color
                v.fill
            end
        elsif total_height < red_height
            vg.path do |v|
                v.rect(pad,yellow_start, 0.2*w, yellow_height)
                v.fill_color bar_color
                v.fill
            end
            vg.path do |v|
                v.rect(pad,total_start, 0.2*w, total_height-yellow_height)
                v.fill_color yellow_color
                v.fill
            end
        elsif total_height >= red_height
            vg.path do |v|
                v.rect(pad,yellow_start, 0.2*w, yellow_height)
                v.fill_color bar_color
                v.fill
            end
            vg.path do |v|
                v.rect(pad,red_start, 0.2*w, red_height-yellow_height)
                v.fill_color yellow_color
                v.fill
            end
            vg.path do |v|
                v.rect(pad,total_start, 0.2*w, total_height - red_height)
                v.fill_color red_color
                v.fill
            end
        end


        vg.path do |v|
            v.rect(0.8*w-pad,(1-v2)*pad2, 0.2*w, (v2)*(h-pad))
            v.fill_color bar_color
            v.fill
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
