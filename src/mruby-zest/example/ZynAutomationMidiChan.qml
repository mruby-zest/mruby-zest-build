Widget {
    id: midi_chan
    onExtern: {
        ext  = midi_chan.extern

        learn_ref = OSC::RemoteParam.new($remote, ext + "learning")
        midi_ref  = OSC::RemoteParam.new($remote, ext + "midi-cc")
        nrpn_ref  = OSC::RemoteParam.new($remote, ext + "midi-nrpn")
        internal_ref  = OSC::RemoteParam.new($remote, ext + "internal")

        midi_ref.mode  = true
        nrpn_ref.mode  = true
        internal_ref.mode  = true
        learn_ref.mode = true

        learn_ref.callback = lambda {|x| midi_chan.learning = x; update_text()}
        midi_ref.callback  = lambda {|x| midi_chan.cc = x;       update_text()}
        nrpn_ref.callback  = lambda {|x| midi_chan.nrpn = x;     update_text()}
        internal_ref.callback  = lambda {|x| midi_chan.internal = x; update_text()}

        midi_chan.valueRef = [learn_ref, midi_ref, nrpn_ref, internal_ref]
    }

    //Workaround due to buggy nested properties
    function valueRef=(value_ref)
    {
        @value_ref = value_ref
    }

    function valueRef()
    {
        @value_ref
    }

    function onSetup(old=nil) {
        @cc       = nil
        @nrpn     = nil
        @internal = nil
        @learning = nil
    }

    function cc=(x)       {@cc = x}
    function nrpn=(x)     {@nrpn = x}
    function internal=(x) {@internal = x}
    function learning=(x) {@learning = x}

    function update_text() {
        @cc = nil       if(@cc.nil?       || @cc < 0)
        @nrpn = nil     if(@nrpn.nil?     || @nrpn < 0)
        @internal = nil if(@internal.nil? || @internal < 1)
        @learning = nil if(@learning.nil? || @learning < 0)

        new_label = text.label;
        if(@internal && !@learning)
            if(@internal==1)
                new_label = "generic modulator ENV"
            elsif(@internal==2)
                new_label = "generic modulator LFO"
            end
        elsif(@cc && !@learning)
            new_label = "MIDI CC #{@cc}"
        elsif(@nrpn && !@learning)
            new_label = "MIDI NRPN #{@nrpn}"
        elsif(!@cc && @learning)
            new_label = "Learning Queue #{@learning}"
        elsif(@cc && @learning)
            new_label = "MIDI CC #{@cc} - Relearning Queue #{@learning}"
        else
            new_label = "Unbound"
        end

        if(new_label != self.label)
            text.label = new_label
            damage_self
        end
    }

    TextBox {
        id: text
    }

    Selector {
        id: sel
        extern: midi_chan.extern + "internal"
    }

    NumEntry {extern: midi_chan.extern + "midi-cc"; label: "CC"}
    NumEntry {extern: midi_chan.extern + "midi-nrpn"; label: "NRPN"}

    function layout(l, selfBox) {
        Draw::Layout::hfill(l, selfBox, children, [0.7,0.1,0.1,0.1,0.1])
    }
}
