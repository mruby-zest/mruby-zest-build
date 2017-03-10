class LayoutConstBox
    attr_accessor :x, :y, :w, :h, :base, :info
    def initialize
        @x = nil
        @y = nil
        @w = nil
        @h = nil
        @info = nil
    end

    def to_s
        "<#{@x},#{@y},#{@w},#{@h}>"
    end
end

class Layout
    
    attr_reader :boxes

    def initialize()
        @boxes = []
    end

    def genConstBox(x, y, w, h, info=nil)
        res = LayoutConstBox.new
        res.info = info
        res.x    = x
        res.y    = y
        res.w    = w
        res.h    = h
        @boxes     << res
        #puts "MADE CONST BOX #{res}"
        res
    end
    
    def aspect(box, ww, hh)
        provided    = box.w/box.h
        recommended = ww/hh
        if(recommended > provided)
            #Decrease height
            new_height = box.h*provided/recommended
            box.y += (box.h-new_height)/2
            box.h = new_height 
        else
            new_width = box.w*recommended/provided
            box.x += (box.w-new_width)/2
            box.w  = new_width
        end
    end
    
    def fixed_long(box, parent, x, y, w, h,
                   xf, yf, wf, hf)
        #puts "fixed_long(#{box.class}, #{parent.class})"
        bx = self.genConstBox(xf+x*parent.w,
                              yf+y*parent.h,
                              wf+w*parent.w,
                              hf+h*parent.h,
                              box)
        box.layout(self, bx)
    end
end
