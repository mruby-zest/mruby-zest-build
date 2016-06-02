module OSC
    class Remote
        attr_accessor :cb_list
        def add_cb(cb)
            if(@cb_list.nil?)
                @cb_list = [cb]
            else
                @cb_list << cb
            end
            puts "list of callbacks include "
            puts @cb_list
        end
    end
    class RemoteMetadata
        attr_accessor :name, :short_name, :units, :tooltip, :options
    end

    class RemoteParam
        attr_accessor :cb_item
        attr_accessor :remote

        # :norm - 0..1 continious valued knob
        def mode=(mode)
        end

        def value=(val)
            set_value(val)
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
            puts "list of callbacks include "
            puts @cb_list
        end
    end
end

