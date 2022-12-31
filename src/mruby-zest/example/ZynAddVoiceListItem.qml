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
        value_label: true
    }
    //pan
    HSlider {
        extern: voice_item.extern + "PPanning"
        value_label: true
        centered: true;
        value: 0.5
    }
    //detune
    ZynDetuneHSlider {
        extern: voice_item.extern + "PDetune"
        extern2: voice_item.extern + "detunevalue"
        centered: true;
    }

    //vib depth
    HSlider {
        extern: voice_item.extern + "FreqLfo/Pintensity"
        value_label: true
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
