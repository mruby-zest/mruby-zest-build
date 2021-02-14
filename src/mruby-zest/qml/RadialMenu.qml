Widget {
    id: radial

    //wouldn't you know, random just lands on the same value that you already
    //had :p
    property Array fields: ["Learn", "Rand", "Unlearn", "default"]

    //The mouse's favorite flavor of pie (or shredded wheaties) 0=N,1=E,2=S,3=W
    property Int   flavor: nil

    property Function callback: nil

    function draw(vg)
    {
        inner  = 0.1*[h,w].min
        outer = 0.5*[h,w].min
        cx = radial.w/2
        cy = radial.h/2
        pi = 3.14159
        start = pi/4;
        end_   = pi*3.0/4.0;
        start = 0
        end_  = -2.0*pi

        vg.path do |v|
            v.arc(cx, cy, outer, start, end_, 1);
            v.arc(cx, cy, inner, end_, start, 2);
            v.close_path
            v.fill_color color("114575",205)
            v.fill
        end

        if(self.flavor)
            start = self.flavor*2*pi/4 - pi/4
            end_  = start-pi/2
            vg.path do |v|
                v.arc(cx, cy, outer, start, end_, 1);
                v.arc(cx, cy, inner, end_, start, 2);
                v.close_path
                v.fill_color color("2185F5", 205)
                v.fill
            end
        end

        vg.path do |v|
            outer = 0.5*0.707*[h,w].min
            v.move_to(cx-outer,cy-outer)
            v.line_to(cx+outer,cy+outer)
            v.move_to(cx+outer,cy-outer)
            v.line_to(cx-outer,cy+outer)
            v.stroke_color color("ffffff")
            v.stroke
        end

        textColor = color("3AC5EC")

        #Draw North
        vg.font_face("bold")
        vg.font_size h/8
        vg.text_align NVG::ALIGN_CENTER | NVG::ALIGN_MIDDLE
        vg.fill_color(textColor)
        vg.text(w*0.5,h*0.2,fields[0].upcase)

        #Draw East
        vg.text(w*0.8,h*0.5,fields[1].upcase)

        #Draw South
        vg.text(w*0.5,h*0.8,fields[2].upcase)

        #Draw West
        vg.text(w*0.2,h*0.5,fields[3].upcase)
    }

    function abs(x)
    {
        if(x < 0)
            return -x
        else
            return x
        end
    }

    function onMouseMove(ev)
    {
        dx = ev.pos.x-self.global_x-radial.w/2
        dy = ev.pos.y-self.global_y-radial.h/2
        slice = find_slice(dx, dy)
        if(slice != self.flavor)
            self.flavor = slice
            self.root.damage_item(self) if(self.root)
        end
    }

    function onMouseRelease(ev) {
        onMousePress(ev)
    }

    function find_slice(dx, dy)
    {
        dist     = (dx**2 + dy**2)**0.5
        min_dist = 0.05*[self.w, self.h].min
        return nil if dist < min_dist
        if(abs(dx) > abs(dy))
            #east vs west
            if(dx > 0)
                return 1
            else
                return 3
            end
        else
            #north vs south
            if(dy < 0)
                return 0
            else
                return 2
            end
        end
    }

    function onMousePress(ev) {
        dx = ev.pos.x-radial.w/2
        dy = ev.pos.y-radial.h/2
        slice = find_slice(dx, dy)
        callback.call(self.flavor) if callback
        rt = radial.root
        rt.ego_death radial
    }
}
