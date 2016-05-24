class Pos
    attr_accessor :x, :y
    def initialize(x,y)
        @x = x
        @y = y
        if(!x || !y)
            throw :invalid_position
        end
    end
    def to_s
        if(!@x || !@y)
            "<INVALID POS>"
        else
            "<Pos:#{@x}, #{@y}>"
        end
    end
end

