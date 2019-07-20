UiEventTypes = [
    :mousePress,
    :mouseRelease,
    :mouseMove,
    :mouseScroll,
    :windowResize,
    :keyPress
]

class MouseScroll
    attr_accessor :x, :y, :dx, :dy, :mod
    def initialize(x,y,dx,dy,mod)
        @x  = x
        @y  = y
        @dx = dx
        @dy = dy
        @mod = Modifiers::get_list_from_int(mod)
    end
end

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
        #try to merge events
        if(event[0] == :windowResize)
            @ev.each do |ev|
                if(ev[0] == :windowResize)
                    ev[1][:w] = event[1][:w]
                    ev[1][:h] = event[1][:h]
                    return
                end
            end
        end
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
