Widget {
    id: env

    property Object prev: nil;
    property Int    selected: nil;
    property Int    selectedcp: nil;
    property Array  xpoints: [0.0, 0.2, 0.7, 0.8, 1.0]
    property Array  ypoints: [0.0, 0.5, 0.3, -0.9, 0.0]
    property Array  cpoints: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    property Int    points: 5
    property Int    sustain_point: 3
    property Object valueRef: nil
    property Bool   mouse_enable: true
    property Function whenTime: nil
    property Int      emode: nil

    function setup_valuerefs()
    {
        ext = env.extern
        xvalues = OSC::RemoteParam.new($remote, ext + "envdt") # array of x values
        yvalues = OSC::RemoteParam.new($remote, ext + "envval") # array of y values
        cyvalues = OSC::RemoteParam.new($remote, ext + "envcpy") # array of control point y values
        pts = OSC::RemoteParam.new($remote, ext + "Penvpoints") # number of points
        pts.mode = :selector
        sus = OSC::RemoteParam.new($remote, ext + "Penvsustain")
        sus.mode = :full
        free = OSC::RemoteParam.new($remote, ext + "Pfreemode")
        mode = OSC::RemoteParam.new($remote, ext + "Envmode")
        mode.mode = :selector
        xvalues.callback = lambda { |x|
            env.xpoints = x
            env.damage_self
            whenTime.call if whenTime
        }
        yvalues.callback = lambda { |x|
            env.ypoints = x.map {|xx| 2*xx-1}
            env.damage_self
        }
        cyvalues.callback = lambda { |x|
            env.cpoints = x
        }
        pts.callback = lambda { |x|
            env.points = x
            env.damage_self
            whenTime.call if whenTime
        }
        sus.callback = lambda { |x|
            env.sustain_point = x
            env.damage_self
        }
        free.callback = lambda { |x|
            env.mouse_enable = x
        }
        mode.callback = lambda { |x|
            env.emode = x
        }
        env.valueRef = [xvalues, yvalues, cyvalues, pts, sus, free, mode]

        run_view.extern = env.extern+"out"
    }

    onExtern: {
        env.setup_valuerefs
    }

    function refresh() {
        return if self.valueRef.nil?
        self.valueRef.each do |v|
            v.refresh
        end
    }

    function get_x_points() {
        cumsum = Draw::DSP::cumsum(xpoints[0...points])
        tmp = Draw::DSP::norm_0_1(cumsum)

        #we need to make sure that the envelopes starts at 0 and finishes at 1
        #(otherwise, the graph won't be displayed correctly)
        tmp[0] = 0
        tmp[-1] = 1

        Draw::DSP::pad_norm(tmp, 0.0001)
    }

    function warp(x)
    {
        wp = get_x_points()
        y = []
        x.each_with_index do |xx, i|
            if((i%2) == 1)
                y << xx
            else
                ps = xx.to_i
                # this shouldn't be needed. TODO: figure out why ps ends up being out of range
                ps = limit(ps, 0, wp.length)
                fr = xx-ps
                ps -= 1
                y << xx if(ps >= wp.length)
                next    if(ps >= wp.length)
                aa = wp[ps]
                bb = wp[ps]
                bb = wp[ps+1] if(ps+1 < wp.length)
                y << aa+fr*(bb-aa)
            end
        end
        y
    }

    function onMousePress(ev) {
        #return if !self.mouse_enable
        #//Try to identify the location  of the nearest grabbable point
        #valuator.prev = ev.pos
        xdat = get_x_points()
        ydat = env.ypoints
        cdat = env.cpoints
        # zip x y and insert control points
        ptsCP = Draw::zipToPosCP(xdat, ydat, cdat)

        n = ptsCP.length
        next_sel = 0
        best_dist = 1e10

        mx = ev.pos.x-global_x
        my = ev.pos.y-global_y
        (0...n).each do |i|
            next if([1,2].include?(i))
            xx = w*ptsCP[i].x;
            yy = h/2-(h/2)*ptsCP[i].y;

            dst = (mx-xx)**2 + (my-yy)**2
            if(dst < best_dist)
                best_dist = dst
                next_sel  = i
            end
        end

        if(env.selected != next_sel )
            env.selected = next_sel
            env.root.damage_item env
        end
        env.prev = ev.pos
    }

    function bound_points(array, low, high)
    {
        n = array.length
        (0...n).each do |i|
            if(array[i] < low)
                array[i] = low
            elsif(array[i] > high)
                array[i] = high
            end
        end
    }

    function onMouseMove(ev) {
        #return if !self.mouse_enable

        if(env.selected)
            scalex = 4*(env.xpoints[(env.selected/2).floor]+10)
            dy = 2*(ev.pos.y - env.prev.y)/env.h
            dx = scalex*(ev.pos.x - env.prev.x)/env.w
            n  = [env.xpoints.length, env.ypoints.length].min

            if(env.selected == 0 || env.selected == n-1)
                env.ypoints[(env.selected/2).floor] -= dy
            elsif (env.selected % 3 == 0)
                env.xpoints[(env.selected/3).floor] += dx
                env.ypoints[(env.selected/3).floor] -= dy
            elsif (env.selected % 3 == 1) # left control point
                env.cpoints[(env.selected/3).floor*2+1] -= dy
            elsif (env.selected % 3 == 2) # right control point
                env.cpoints[(env.selected/3).floor*2+2] -= dy
            end

            bound_points(env.xpoints,  0.0, 40950.0)
            bound_points(env.ypoints, -1.0, 1.0)
            bound_points(env.cpoints, -2.0, 2.0)

            send_points() if mouse_enable
            update_nonfree_x(env.xpoints) if !mouse_enable
            update_nonfree_y(env.ypoints) if !mouse_enable
            valueRef[2].value = env.cpoints if !mouse_enable

            env.prev = ev.pos
            env.root.damage_item env
        end
    }

    function cvt_x(x)
    {
        fval = Math::log2(x/10.0 + 1.0) * 127.0/12.0
        (2**(12*([0.0, [127.0, fval].min].max)/127.0)-1)/100.0
    }

    function update_nonfree_x(pts)
    {
        if(emode == 1)
            $remote.setf(extern + "A_dt", cvt_x(pts[1]))
            $remote.setf(extern + "D_dt", cvt_x(pts[2]))
            $remote.setf(extern + "R_dt", cvt_x(pts[3]))
        elsif(emode == 2)
            $remote.setf(extern + "A_dt", cvt_x(pts[1]))
            $remote.setf(extern + "D_dt", cvt_x(pts[2]))
            $remote.setf(extern + "R_dt", cvt_x(pts[3]))
        elsif(emode == 3)
            $remote.setf(extern + "A_dt", cvt_x(pts[1]))
            $remote.setf(extern + "R_dt", cvt_x(pts[2]))
        elsif(emode == 4)
            $remote.setf(extern + "A_dt", cvt_x(pts[1]))
            $remote.setf(extern + "D_dt", cvt_x(pts[2]))
            $remote.setf(extern + "R_dt", cvt_x(pts[3]))
        elsif(emode == 5)
            $remote.setf(extern + "A_dt", cvt_x(pts[1]))
            $remote.setf(extern + "R_dt", cvt_x(pts[2]))
        end
        whenTime.call if whenTime
    }

    function cvt_y(x)
    {
        [0, [127, 127*(x+1)/2].min].max.to_i
    }

    function update_nonfree_y(pts)
    {
        if(emode == 1)
            pts[0]      = -1.0
            pts[1]      = +1.0
            $remote.seti(extern + "PS_val", cvt_y(pts[2]))
            pts[3]      = -1.0
        elsif(emode == 2)
            pts[0]      = -1.0
            pts[1]      = +1.0
            $remote.seti(extern + "PS_val", cvt_y(pts[2]))
            pts[3]      = -1.0
        elsif(emode == 3)
            $remote.seti(extern + "PA_val", cvt_y(pts[0]))
            pts[1]      = 0.0
            $remote.seti(extern + "PR_val", cvt_y(pts[2]))
        elsif(emode == 4)
            $remote.seti(extern + "PA_val", cvt_y(pts[0]))
            $remote.seti(extern + "PD_val", cvt_y(pts[1]))
            pts[2]      = 0.0
            $remote.seti(extern + "PR_val", cvt_y(pts[3]))
        elsif(emode == 5)
            $remote.seti(extern + "PA_val", cvt_y(pts[0]))
            pts[1]      = 0.0
            $remote.seti(extern + "PR_val", cvt_y(pts[2]))
        end
    }


    function send_points()
    {
        return if self.extern.nil?
        ry = ypoints.map {|xx| (xx+1)/2}
        valueRef[0].value = env.xpoints
        valueRef[1].value = ry
        valueRef[2].value = env.cpoints
    }

    function class_name()
    {
        "Envelope"
    }

    function draw(vg)
    {
        xdat = get_x_points()
        ydat = env.ypoints
        cdat = env.cpoints

        fill_color    = Theme::VisualBackground
        stroke_color  = Theme::VisualStroke
        light_fill    = Theme::VisualLightFill
        bright        = Theme::VisualBright
        dim           = Theme::VisualDim
        sel_color     = Theme::VisualSelect
        sustain_color = Theme::SustainPoint

        padfactor = 12
        bb = Draw::indent(Rect.new(0,0,w,h), padfactor, padfactor)

        # insert control points
        ptsCP = Draw::zipToPosCP(xdat, ydat, cdat)
        ptsEnv = Draw::zipToPosEnv(xdat, ydat, cdat)

        background(fill_color)

        #Draw borders of the envelope display
        vg.translate(0.5, 0.5)
        vg.path do |v|
            v.stroke_width = 1
            v.stroke_color = Theme::GridLine
            v.rounded_rect(bb.x.round(), bb.y.round(), bb.w.round(), bb.h.round(), 2)
            v.stroke()
        end
        vg.translate(-0.5, -0.5)

        #Draw Zero Line
        Draw::WaveForm::zero_line(vg, bb, dim)

        #Indicate Sustain Point
        Draw::WaveForm::env_sel_line(vg, bb, self.sustain_point*3, ptsCP, sustain_color)

        #Draw Actual Line
        Draw::WaveForm::env_plot(vg, bb, ptsEnv, bright, selected, emode)
        Draw::WaveForm::env_draw_markers(vg, bb, ptsCP, bright, selected, emode)

    }
    Widget {
        id: run_view
        //animation layer
        layer: 1

        //extern is cloned
        extern: run_view.parent.extern

        function class_name()
        {
            "EnvVisAnimation"
        }

        //Workaround due to buggy nested properties
        function valueRef=(value_ref)
        {
            @value_ref = value_ref
        }

        function valueRef()
        {
            @value_ref
        }

        function runtime_points()
        {
            return @runtime_points
        }

        function runtime_points=(pts)
        {
            @runtime_points = pts
        }

        onExtern: {
            return if run_view.extern.nil?
            run_view.valueRef = OSC::RemoteParam.new($remote, run_view.extern)
            run_view.valueRef.set_watch
            run_view.valueRef.callback = Proc.new {|x|
                y = run_view.runtime_points
                if(y.nil? || y.length != 0 || x.length != 0)
                    run_view.update_points(env.warp(x))
                    run_view.runtime_points = env.warp(x);
                    run_view.root.damage_item run_view
                end
            }
        }

        function update_points(xx)
        {
            self.runtime_points = xx
            damage_self

            @last = Time.new
        }

        function animate()
        {
            run_view.valueRef.watch
            now     = Time.new
            @last ||= now
            update_points([]) if((now-@last)>0.1)
        }

        function draw(vg)
        {
            sel_color    = Theme::VisualSelect
            dim_color    = Theme::VisualDimTrans
            #Draw the data
            pts   = @runtime_points
            pts ||= []
            return if pts.class != Array

            padfactor = 12
            bb = Draw::indent(Rect.new(0,0,w,h), padfactor, padfactor)

            Draw::WaveForm::overlay(vg, bb, pts)
        }
    }
}
