module OSC
    class Remote
        attr_accessor :cb_list
        def add_cb(cb)
            if(@cb_list.nil?)
                @cb_list = [cb]
            else
                @cb_list << cb
            end
            #puts "list of callbacks include "
            #puts @cb_list
        end
    end
    class RemoteMetadata
        attr_accessor :name, :short_name, :units, :tooltip, :options
    end

    class RemoteParam
        attr_accessor :cb_item
        attr_accessor :remote

        # :norm - 0..1 continious valued knob
        attr_accessor :mode

        def value=(val)
            set_value(val*1.0, @mode)
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

        def midi_learn()
            puts "MIDI Learn Action"
            puts "/midi/learn :s "
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

