Widget {
    id: mixer
    property Object valueRef: nil
    property Object data: nil

    function animate() {
        #self.valueRef.refresh if(self.valueRef)

        if(self.data)
            children[0].set_level(data[0], data[1])
            (0..15).each do |i|
            children[i+1].set_level(data[6+2*i], data[6+2*i+1])
            end
        end
    }

    function update_data(x)
    {
        self.data = x
    }

    function draw(vg) {
        vg.path do |v|
            v.rect(0,0,w,h)
            paint = v.linear_gradient(0,0,0,h,
            Theme::InnerGrad1, Theme::InnerGrad2)
            v.fill_paint paint
            v.fill
            v.stroke_color color(:black)
            v.stroke_width 1.0
            v.stroke
        end
    }
    function onSetup(old=nil)
    {
        return if children.length > 3
        col = Qml::ZynMixerMasterCol.new(db)
        Qml::add_child(self, col)
        (0...16).each do |r|
            col = Qml::ZynMixerCol.new(db)
            col.label  = (1+r).to_s
            col.idx    = r
            col.extern = "/part#{r}/"
            Qml::add_child(self, col)
        end

        self.valueRef = OSC::RemoteParam.new($remote, "/vu-meter")
        self.valueRef.callback = lambda {|x| mixer.update_data(x) }
        animate() if self.data
    }

    function class_name() { "mixer" }
    function layout(l, selfBox) {
        Draw::Layout::hpack(l, selfBox, children, 0.02, 0.96, 4)
    }
}
