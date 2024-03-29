Widget {
    id: log
    property Int lines: 2
    property Object extRef: nil
    property Symbol type: :tooltip
    property String statusMsg: ""

    function display_log(type, message, src)
    {
        if(type == :warning)
            if(self.statusMsg != message)
                self.statusMsg = message
                self.type = type
                damage_self
            end
        elsif(self.label != message)
            self.label = message
            self.statusMsg = ""
            self.type = type
            damage_self
        end
    }

    onExtern: {
        log.extRef = OSC::RemoteParam.new($remote, log.extern)
        log.extRef.callback = Proc.new {|x| display_log(:warning, x, "extern") }
    }

    function onSetup(old)
    {
        self.root.log_widget = self
    }

    function draw(vg)
    {
        textColor  = color("3ac5ec") # Default, for tooltips
        textColor  = color("1ac52c") if(self.type == :success) # Green-ish
        msgColor  = color("ea152c") # Red-ish
        splitColor = color("133A4C")

        vg.path do |vg|
            vg.move_to(0,0.5*h)
            vg.line_to(w,0.5*h)
            vg.stroke_width 2.0
            vg.stroke_color splitColor
            vg.stroke
        end

        vg.font_face("bold")
        vg.font_size h/self.lines*0.8
        vg.text_align NVG::ALIGN_LEFT | NVG::ALIGN_MIDDLE
        vg.fill_color(textColor)
        vg.text_box(0,h/4,w,self.label.upcase)
        vg.fill_color(msgColor)
        vg.text_box(0,3*h/4,w,self.statusMsg.upcase)
    }
}
