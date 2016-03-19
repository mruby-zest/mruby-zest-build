#ms based code profiler
class TimeProfile
    attr_reader :avg, :last
    def initialize
        @avg  = 16
        @last = 0
    end

    def start
        @t = Time.new
    end

    def stop
        @last = 1000*(Time.new-@t)
        @avg  = @avg*0.99+0.01*@last
    end

    def avg_hz
        1000/@avg
    end

    def time(&block)
        start
        block.call
        stop
    end
end
