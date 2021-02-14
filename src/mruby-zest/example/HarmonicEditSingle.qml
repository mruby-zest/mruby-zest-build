ColorBox {
    property Function whenValue: nil
    property Int      num: 0
    property Symbol   slidetype: nil
    id: hes
    bg: nil

    function cb()
    {
        whenValue.call if whenValue
    }

    Slider {
        value: 0.5
        pad: 0
        centered: hes.slidetype == :oscil
        extern: {
            if(hes.slidetype == :oscil)
                hes.extern + "magnitude" + hes.num.to_s
            else
                hes.extern + "Phmag" + hes.num.to_s
            end
        }
        whenValue: lambda {hes.cb}

        function onSetup(old=nil) {
            undef :onMousePress if self.respond_to?(:onMousePress)
            undef :onMouseMove  if self.respond_to?(:onMouseMove)
        }
    }
    Text {
        layoutOpts: [:ignoreAspect]
        height: 1.0
        label: (1+hes.num).to_s
    }

    Slider {
        value: 0.5
        pad: 0
        centered: hes.slidetype == :oscil
        extern: {
            if(hes.slidetype == :oscil)
                hes.extern + "phase" + hes.num.to_s
            else
                hes.extern + "Phrelbw" + hes.num.to_s
            end
        }
        whenValue: lambda {hes.cb}

        function onSetup(old=nil) {
            undef :onMousePress if self.respond_to?(:onMousePress)
            undef :onMouseMove  if self.respond_to?(:onMouseMove)
        }

    }

    function layout(l, selfBox)
    {
        children[0].fixed(l, selfBox, 0.0, 0.00, 1.0, 0.47)
        children[1].fixed(l, selfBox, 0.0, 0.48, 1.0, 0.08)
        children[2].fixed(l, selfBox, 0.0, 0.57, 1.0, 0.43)
        selfBox
    }

    function onSetup(v=nil)
    {
        children.each do |c|
            c.extern()
        end
    }
}
