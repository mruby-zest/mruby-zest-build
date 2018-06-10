class Sched
    def initialize
        @active_ev = [:frame, 0, 0]
        @event_list = []
        @scheduled_events = []
        @frame_id = 0
    end

    def active_event(ev)
        @active_ev = ev
    end

    #Adds a new callback when the
    #conditions of the active event
    #are satisfied
    def add(callback)
        @event_list << [@active_ev,
                        callback]
    end

    def tick(runner)
        print '#'
        #puts "sched tick"
        @frame_id += 1

        to_delete = []
        @event_list.each_with_index do |e,i|
            if(e[0][1]+e[0][2] < @frame_id)
                to_delete << i
                e[1].call(runner)
            end
        end
        puts "E" if to_delete.length != 0
        to_delete.reverse.each do |i|
            @event_list.delete_at(i)
        end
    end
end
