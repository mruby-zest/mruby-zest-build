Widget {
    id: voice_item
    property Int   num:     0
    property Array weights: [0.05, 0.05, 0.05, 0.2, 0.2, 0.3, 0.15]

    //voice ID
    ToggleButton {
        extern: voice_item.extern + "Enabled"
        label: (voice_item.num+1).to_s;
        layoutOpts: [:no_constraint]
    }
    //AA Enabled
    ToggleButton {
        extern: voice_item.extern + "PAAEnabled"
        label: "AA";
    }
    //mini wave view
    WaveView {
        extern: voice_item.extern + "OscilSmp/waveform"
        noise:  voice_item.extern + "Type"
        grid: false;
    }
    //volume
    HSlider {
        extern: voice_item.extern + "PVolume"
        label: "20%"
    }
    //pan
    HSlider {
        extern: voice_item.extern + "PPanning"
        label: "centered";
        centered: true;
        value: 0.5
    }
    //detune
    HSlider {
        extern: voice_item.extern + "PDetune"
        label: "+0 cents";
        centered: true;
        value: 0.5
    }

    //vib depth
    HSlider {
        extern: voice_item.extern + "FreqLfo/Pintensity"
        label: "100%"
    }

    function layout(l, selfBox)
    {
        chBox   = []

        off = 0.0
        hpad = 1.0/128
        children.each_with_index do |ch, ind|
            weight = weights[ind]
            ch.fixed(l, selfBox, off+hpad, 0.0, weight-2*hpad, 1.0)
            off += weight
        end
        selfBox
    }

    function onSetup(old=nil)
    {
        children.each do |x|
            x.extern()
        end
    }
}
