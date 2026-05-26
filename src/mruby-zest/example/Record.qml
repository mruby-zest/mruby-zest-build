Widget {
    property Symbol state: :notsetup

    function draw(vg)
    {
        pad  = 1.0/64
        pad2 = (1-2*pad)
        vg.path do |v|
            v.rect(w*pad, h*pad, (2.0/3)*w*pad2, h*pad2)
            paint = v.linear_gradient(0,0,0,h,
            Theme::ButtonGrad1, Theme::ButtonGrad2)
            v.fill_paint paint
            v.fill
            v.stroke_width 1
            v.stroke
        end

        vg.path do |v|
            v.move_to(w*1.0/3, 0)
            v.line_to(w*1.0/3, h)
            v.stroke
        end

        text_color = Theme::TextColor
        active_color = Theme::TextActiveColor

        draw_stop(vg, active_color, text_color)
        draw_playpause( vg, active_color, text_color)
    }

    function draw_record(vg, active_color, text_color) {
        color = (self.state == :stopped || self.state == :paused) ? active_color : text_color
        r = [1.0/6*w, 1.0/2*h].min*0.4
        vg.path do |v|
            v.circle(1.0/6*w, 1.0/2*h, r)
            v.fill_color text_color
            v.fill
        end
    }

    function draw_stop(vg, active_color, text_color) {
        color = (self.state == :recording || self.state == :paused) ? active_color : text_color
        r = [1.0/6*w, 1.0/2*h].min*0.4
        vg.path do |v|
            v.rect(1.0/6*w-r, 1.0/2*h-r, 2*r, 2*r)
            v.fill_color color
            v.fill
        end
    }

    function draw_pause(vg, active_color, text_color) {
        color = (self.state == :recording) ? active_color : text_color
        vg.path do |v|
            v.rect((3.0/6-1.0/18)*w, 0.2*h, 1.0/24*w, 0.6*h)
            v.rect((3.0/6+1.0/18)*w, 0.2*h, 1.0/24*w, 0.6*h)
            v.fill_color color
            v.fill
        end
    }

    function draw_play(vg, active_color, text_color) {
        color = (self.state == :stopped || self.state == :paused) ? active_color : text_color
        vg.path do |v|
            v.move_to((3.0/6-1.0/18)*w, 0.25*h)
            v.line_to((3.0/6-1.0/18)*w, 0.75*h)
            v.line_to((3.0/6+1.0/18)*w, 0.5*h)
            v.close_path
            v.fill_color color
            v.fill
        end
    }

    function draw_playpause(vg, active_color, text_color) {
        if(self.state == :recording)
            draw_pause(vg, active_color, text_color)
        else
            draw_play(vg, active_color, text_color)
        end
    }

    function handleToolTip(ev) {
        if (root.isPlugin)
            dsp = "Recorder not available in Plugin mode"
        else
            if(self.state == :notsetup) then
                dsp = "Use \"File -> Setup Record\" to use Recorder"
            else
                px = (ev.pos.x-global_x)*1.0/w
                if(px <= 0.333)
                    dsp = "Stop"
                elsif(px > 0.333 && px < 0.666) then
                    if(self.state == :recording) then
                        dsp = "Pause"
                    else
                        dsp = "Start"
                    end
                end
            end
        end
        self.root.log(:tooltip, dsp)
    }

    function onMouseHover(ev) {
        handleToolTip(ev)
    }

    function onMouseEnter(ev) {
        handleToolTip(ev)
    }

    function onMousePress(ev) {
        if(self.state != :notsetup) then
            px = (ev.pos.x-global_x)*1.0/w
            if(px > 0.333 && px < 0.666) then # play/pause button
                if(self.state == :recording) then
                    $remote.action("/HDDRecorder/pause")
                    self.state = :paused
                else
                    # it is stopped or paused
                    $remote.action("/HDDRecorder/start")
                    self.state = :recording
                end
                damage_self
            else  # stop button
                if(self.state == :recording || self.state == :paused)
                    $remote.action("/HDDRecorder/stop")
                    self.state = :notsetup
                    damage_self
                end
            end
        end
    }

    function onRecordSetup() {
        self.state = :stopped
        damage_self
    }
}
