class DrawSeqNode
    attr_reader :x, :y, :w, :h, :item
    def initialize(x,y,w,h,item)
        @x    = x
        @y    = y
        @w    = w
        @h    = h
        @item = item
    end
end

