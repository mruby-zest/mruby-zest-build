class Rect
    attr_accessor :x, :x2, :y, :y2, :w, :h
    def initialize(x,y,w,h)
        @x = x
        @y = y
        @w = w
        @h = h
    end

    def include(x,y)
        x>=@x && x<=@x+@w && y>=@y && y<=@y+@h
    end

    def include?(pos)
        include(pos.x, pos.y)
    end
end
