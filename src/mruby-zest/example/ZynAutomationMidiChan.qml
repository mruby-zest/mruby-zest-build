TextBox {
    id: midi_chan
    onExtern: {
        ext  = midi_chan.extern

        learn_ref = OSC::RemoteParam.new($remote, ext + "learning")
        midi_ref  = OSC::RemoteParam.new($remote, ext + "midi-cc")
        nrpn_ref  = OSC::RemoteParam.new($remote, ext + "midi-nrpn")

        midi_ref.mode  = true
        nrpn_ref.mode  = true
        learn_ref.mode = true

        learn_ref.callback = lambda {|x| midi_chan.learning = x; update_text()}
        midi_ref.callback  = lambda {|x| midi_chan.cc = x;       update_text()}
        nrpn_ref.callback  = lambda {|x| midi_chan.nrpn = x;     update_text()}


        midi_chan.valueRef = [learn_ref, midi_ref]
    }

    function update_text() {
        @cc = nil       if(@cc.nil?       || @cc < 0)
        @nrpn = nil     if(@nrpn.nil?     || @nrpn < 0)
        @learning = nil if(@learning.nil? || @learning < 0)

        new_label = self.label;
        if(@cc && !@learning)
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
            self.label = new_label
            damage_self
        end
    }

    function onSetup(old=nil) {
        @cc       = nil
        @nrpn       = nil
        @learning = nil
    }

    function cc=(x)       {@cc = x}
    function nrpn=(x)       {@nrpn = x}
    function learning=(x) {@learning = x}

}
