HSlider {
    id: detslide
    property Object valueview: nil
    property String extern2: nil
    
    label: " ";
    centered: true;
    
    onExtern2: {
        detslide.valueview = OSC::RemoteParam.new($remote,
        detslide.extern2)
        detslide.valueview.type = "f"
        detslide.valueview.callback = Proc.new {|x|
            if(x.class == Float)
                x = x.round(3)
            end
            detslide.label = x.to_s+ " cents"
        }
        detslide.valueview.refresh
    }

    whenValue: lambda {
        return unless detslide.valueview
        detslide.valueview.refresh
    }
}
