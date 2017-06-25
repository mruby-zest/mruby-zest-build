class Automations
    attr_accessor :active_auto, :learn_midi, :remote, :mode
    MAX_SLOT = 16
    MAX_AUTO = 8
    def learn_address(path)
        if(mode == :normal)
            remote.action("/automate/learn-binding-new-slot", path)
        else
            remote.action("/automate/learn-binding-same-slot", path)
        end
    end
end

module OSC
    class Remote
        attr_accessor :cb_list
        attr_accessor :automation
        def init_automate
            @automation = Automations.new
            @automation.active_auto = -1
            @automation.learn_midi  = true
            @automation.remote      = self
            @automation.mode        = :normal
        end
        def add_cb(cb)
            if(@cb_list.nil?)
                @cb_list = [cb]
            else
                @cb_list << cb
            end
            #puts "list of callbacks include "
            #puts @cb_list
        end

        def automate(ext)
            puts "Automation Setup"
            puts "Trying to bind address '#{ext}' to a slot"
            @automation.learn_address(ext)
        end
    end
    class RemoteMetadata
        attr_accessor :name, :short_name, :units, :scale, :tooltip, :options
        attr_accessor :min, :max
    end

    class RemoteParam
        attr_accessor :cb_item
        attr_accessor :remote

        # :norm - 0..1 continious valued knob
        attr_accessor :mode

        def value=(val)
            val = 0 if val.nil?
            set_value(val*1.0, @mode) if(val.class == Fixnum || val.class == Float)
            set_value_tf(val,  @mode) if(val.class == TrueClass || val.class == FalseClass)
            set_value_ar(val,  @mode) if(val.class == Array)
            set_value_str(val, @mode) if(val.class == String)
        end


        def callback=(cb)
            set_callback(cb)
        end

        def invalidate()
        end
        def add_cb(cb)
            if(@cb_list.nil?)
                @cb_list = [cb]
            else
                @cb_list << cb
            end
            #puts "list of callbacks include "
            #puts @cb_list
        end

        def midi_learn(ext=nil)
            puts "MIDI Learn Action"
            puts "/midi/learn :s "
            puts "trying to learn address #{ext}"
        end

        def rand()
        end

        def midi_unlearn()
            puts "MIDI Learn Action"
            puts "/midi/unlearn :s "
        end

        def default()
        end
    end
end

