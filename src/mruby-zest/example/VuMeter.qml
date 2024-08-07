Widget {
    id: meter
    property Object valueRef: nil
    property Object data: nil

    function animate() {
        self.valueRef.refresh if(self.valueRef)
    }

    function rap2dB(x) { 20*Math::log10(x) }
    function lowerbound(x)  { [0.0, x].max }
    function cv(x)     {min_db = -40;lowerbound((min_db-rap2dB(x))/min_db)}

    function draw(vg)
    {
        indent_color = Theme::VisualBackground
        background indent_color

        bar_color = Theme::VisualLine
        pad  = 3
        pad2 = (h-2*pad)
        v1 = 0.3
        v2 = 0.5
        if(!data.nil?)
            v1 = cv(data[0])
            v2 = cv(data[1])
        end

        
        
        # Farben im gewünschten Format
        green_color = color("00FF55")  # Grün
        yellow_color = color("FFCC00")  # Gelb
        red_color = color("FF0000")  # Rot

        total_height = (v1)*(h-pad)
        total_start = (1-v1)*pad2
        yellow_height = (cv(0.25)) * (h-pad)
        yellow_start = (1-cv(0.25))*pad2
        red_height = ((cv(0.95)) * (h-pad))
        red_start = (1-cv(0.95))*pad2
  
            
            
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
