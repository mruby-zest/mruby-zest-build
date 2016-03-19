UiEventTypes = [
    :mousePress,
    :mouseRelease,
    :mouseMove,
    :windowResize,
    :keyPress
]

class UiEventSeq
    attr_accessor :events, :ev, :frame
    def initialize
        @events = Hash.new
        @ev     = []
        @frame  = 0
        @ignore = 0
    end

    def ignore
        @ignore += 1
    end

    def next_frame
        if(!@ev.empty?)
            @events[@frame] = ev
        end
        @ev     = []
        @frame += 1
        if(@events.include? @frame)
            @ev = @events[@frame]
        end
    end

    def record(event)
        if(@ignore == 0)
            @ev << event
        else
            @ignore -= 1
        end
    end

    def dump(f=$stdout)
        events.each do |frame,evs|
            f.puts "frame #{frame}"
            evs.each do |ev|
                [ev[0], ev[1].to_a].flatten.each do |x|
                    f.print x
                    f.print ' '
                end
                f.puts  
            end
        end
    end

    def reload(f)
        while(!f.eof?)
            dat = f.gets.split
            inds = dat.length
            ev_type = dat[0].to_sym
            if(ev_type == :frame)
                @frame = dat[1].to_i
            else
                ev_prop = Hash.new
                ind = 1
                while(ind < inds)
                    ev_prop[dat[ind].to_sym] = dat[ind+1].to_f
                    ind += 2
                end

                if(@events.include? @frame)
                    @events[@frame] << [ev_type, ev_prop]
                else
                    @events[@frame] = [[ev_type, ev_prop]]
                end
            end
        end
        puts @events
        @frame = 0
    end
end
