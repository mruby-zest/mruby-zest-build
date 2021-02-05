#Layers
#-1 - merged     layer
# 0 - background layer
# 1 - animation  layer
# 2 - overlay    layer

class FakeWindow
    attr_accessor :w, :h
    def initalize()
        @ref = nil
    end

    def refresh
        @ref = true
    end

    def clear_refresh
        @ref = nil
    end

    def get_refresh
        @ref
    end
end

class ZRunner
    def initialize(url)
        GL::debug "[INFO] setting up runner"
        $global_self = self
        @events   = UiEventSeq.new
        @draw_seq = DrawSequence.new
        @mx       = 0
        @my       = 0
        @clicked  = nil
        @keyboard = nil

        @animate_frame_dt   = 1.0/30.0
        @animate_frame_next = Time.new

        #Framebuffers
        @background_fbo = nil
        @animation_fbo  = nil
        @overlay_fbo    = nil
        @redraw_fbo     = nil

        @background_img = nil
        @animation_img  = nil
        @overlay_img    = nil
        @redraw_img     = nil

        #Misc
        @hotload = true
        $sched = nil

        @startup_time = Time.new

        #global stuff?
        GL::debug "[INFO] Loading Remote Interface"
        $remote = OSC::Remote.new(url)
        GL::debug "[INFO] Done Loading Remote Interface"


        @view_pos              = Hash.new
        @view_pos[:part]       = 0
        @view_pos[:kit]        = 0
        @view_pos[:view]       = :banks
        @view_pos[:voice]      = 0
        @view_pos[:subview]    = :global
        @view_pos[:subsubview] = nil
        @view_pos[:vis]        = :env
        @view_pos[:slot]       = 0
    end

    def search_path=(val)
        @search_path = val
    end

    ########################################
    #       Graphics Init Routines         #
    ########################################

    def init_window(block)
        GL::debug "[INFO] init window"
        @window = FakeWindow.new
        @window.w = @w
        @window.h = @h
        @draw_seq.window = @window
        @widget = block.call
        if(!@widget)
            GL::debug "[ERROR] No Widget was allocated"
            GL::debug "[ERROR] This is typically a problem with running the code from the wrong subdirectory"
            GL::debug "[ERROR] If mruby-zest cannot find the qml source files, then the UI cannot be created"
            raise "Impossible Widget"
        end
        GL::debug "[INFO] widget loaded"

        @widget.w = @w
        @widget.h = @h
        @widget.parent = self

        GL::debug "[INFO] doing setup"
        doSetup(nil, @widget)

        GL::debug "[INFO] doing layout"
        perform_layout
        GL::debug "[INFO] makeing draw seq"
        @animated = []
        @draw_seq.make_draw_sequence(@widget)
        GL::debug "[INFO] draw sequence ready"

        @widget.db.make_rdepends
        @draw_seq.damage_region(DrawRect.new(0, 0, @w, @h), 0)
        @draw_seq.damage_region(DrawRect.new(0, 0, @w, @h), 1)
        @draw_seq.damage_region(DrawRect.new(0, 0, @w, @h), 2)
    end

    def setup
        GL::debug "[INFO] setup..."
        if(!@widget)
           GL::debug "[ERROR] No Widget was allocated"
           GL::debug "[ERROR] This is typically a problem with running the code from the wrong subdirectory"
           GL::debug "[ERROR] If mruby-zest cannot find the qml source files, then the UI cannot be created"
            raise "Impossible Widget"
        end


        #Setup OpenGL Interface
        init_pugl

        if(@widget.label)
            @window.title = @widget.label
        end

        #Initial sizing
        #if(@widget.w && @widget.h)
        #    #resize(@widget.w, @widget.h)
        #    #@window.size = [@widget.w, @widget.h]
        #else
            @widget.w,@widget.h = [1181, 659]#@window.size
        #end
            @widget.parent = self

        doSetup(nil, @widget)

        perform_layout
        @draw_seq.make_draw_sequence(@widget)

        @widget.db.make_rdepends
    end

    def init_pugl
        GL::debug "[INFO] init pugl"
        @window = GL::PUGL.new self
        @draw_seq.window = @window
        init_gl
        @window.impl = self
    end

    def init_font
        search   = @search_path
        search ||= ""
        font_error = false
        sans = [search + "font/Roboto-Regular.ttf", "deps/nanovg/example/Roboto-Regular.ttf"]
        if(@vg.create_font('sans', sans[0]) == -1 && @vg.create_font('sans', sans[1]) == -1)
           GL::debug "[ERROR] could not find sans font"
            font_error = true
        end

        bold = [search + "font/Roboto-Bold.ttf", "deps/nanovg/example/Roboto-Bold.ttf"]
        if(@vg.create_font('bold', bold[0]) == -1 && @vg.create_font('bold', bold[1]) == -1)
           GL::debug "[ERROR] could not find bold font"
            font_error = true
        end
        exit if font_error
    end

    def init_gl
        GL::debug "[INFO] init gl"
        #@window.make_current
        #@window.size = [1181,659]
        #@w,@h=*@window.size
        @w = 1181
        @h = 659

        GL::debug "[INFO] init nanovg instance"
        @vg     = NVG::Context.new(NVG::ANTIALIAS | NVG::STENCIL_STROKES | NVG::DEBUG)

        #Global Initialize
        $vg     = @vg

        #Load Fonts
        GL::debug "[INFO] loading fonts"
        init_font

        #Load Overlay image
        #@backdrop = @vg.create_image('../template.png', 0)
        GL::debug "[INFO] window width=#{@w}"
        GL::debug "[INFO] window height=#{@h}"

        build_fbo

    end

    def build_fbo
        @background_fbo = GL::FBO.new(@w, @h)
        @animation_fbo  = GL::FBO.new(@w, @h)
        @overlay_fbo    = GL::FBO.new(@w, @h)
        @redraw_fbo     = GL::FBO.new(@w, @h)
    end


    ########################################
    #            Event Handling            #
    ########################################

    #holds true only in cases of a spacial partitioning
    def activeWidget(mx=@mx, my=@my, ev=nil)
        @draw_seq.event_widget(mx, my, ev)
    end

    def findWidget(ev)
        @draw_seq.find_widget(ev)
    end

    def handleMousePress(mouse)
        aw = activeWidget(mouse.pos.x, mouse.pos.y, :onMousePress)
        if(aw.respond_to? :onMousePress)
            aw.onMousePress mouse
        else
            GL::debug "no mouse press option..."
        end
        @modal.onMousePress(mouse) if(@modal && @modal.respond_to?(:onMousePress))
        @window.refresh
        @clicked = Pos.new(@mx,@my)
        @keyboard = Pos.new(@mx, @my)
    end

    def handleMouseRelease(mouse)
        aw = nil
        aw = activeWidget(@clicked.x, @clicked.y) if @clicked
        aw = activeWidget if @clicked.nil?
        @clicked = nil
        if(aw.respond_to? :onMouseRelease)
            aw.onMouseRelease mouse
        end
    end

    def handleCursorPos(x,y,mod)
        old_aw = activeWidget(@mx, @my)
        @mx = x
        @my = y
        if(@clicked)
            aw = activeWidget(@clicked.x, @clicked.y, :onMousePress)
            if(aw.respond_to? :onMouseMove)
                aw.onMouseMove MouseButton.new(0,Pos.new(x,y),mod)
            end
        else
            aw = activeWidget(x, y)
            if(aw.respond_to? :onMouseHover)
                aw.onMouseHover MouseButton.new(0,Pos.new(x,y),mod)
            end
            # It's important that onMouseLeave is called before onMouseEnter
            # for tooltips to work properly.
            if(aw != old_aw && old_aw.respond_to?(:onMouseLeave))
                old_aw.onMouseLeave MouseButton.new(0,Pos.new(x,y),mod)
            end
            if(aw != old_aw && aw.respond_to?(:onMouseEnter))
                aw.onMouseEnter MouseButton.new(0,Pos.new(x,y),mod)
            end
        end
    end

    def handleScroll(x, y, scroll)
        aw = activeWidget(x, y, :onScroll)
        aw.onScroll scroll if(aw.respond_to? :onScroll)
    end

    def quit
        @keep_running = false
        @quit_time = Time.new + 0.5
        $remote.action("/quit")
    end

    def exit?
        tmp = @quit_time && @quit_time < Time.new
        if(tmp)
            tmp
        else
            nil
        end
    end

    def resize(w,h)
        #@resize_start = Time.new
        #puts "resize event... #{Time.new}"
        #puts "resize to #{w}, #{h}"
        @events.record([:windowResize, {:w => w, :h => h}])
    end

    def cursor(x,y,mod)
        @events.record([:mouseMove, {:x => x, :y => y, :mod => mod}])
    end

    def key_mod(press, key)
        press = press.to_sym
        key   = key.to_sym
        GL::debug "mod press #{press} with #{key}"
        if(press == :press && key == :ctrl)
            @learn_mode = true
        elsif(press == :release && key == :ctrl)
            @learn_mode = false
        end

        if(press == :press && key == :shift)
            @fine_mode = true
        elsif(press == :release && key == :shift)
            @fine_mode = false
        end

        begin
            aw = nil
            if @keyboard
                aw = activeWidget(@keyboard.x, @keyboard.y, :onSpecial)
            end

            if aw.nil?
                aw = findWidget(:onSpecial)
            end
            aw.onSpecial(key, press) if(aw.respond_to? :onSpecial)
        end
    end

    def key(key, act)
        aw = nil
        if @keyboard
            aw = activeWidget(@keyboard.x, @keyboard.y, :onKey)
        end

        if(key == "z" && act == "press" && @learn_mode)
            $remote.action("/undo") 
        end

        if(key == "y" && act == "press" && @learn_mode)
            $remote.action("/redo") 
        end


        if aw.nil?
            aw = findWidget(:onKey)
        end
        aw.onKey(key, act) if(aw.respond_to? :onKey)
    end

    def key_widget
        if @keyboard
            activeWidget(@keyboard.x, @keyboard.y, :onKey)
        end
    end

    def mouse(button, action, x, y, mod)
        if(action == 1)
            @events.record([:mousePress,   {:button => button, :action => action, :mod => mod}])
        else
            @events.record([:mouseRelease, {:button => button, :action => action, :mod => mod}])
        end
    end

    def scroll(x, y, dx, dy, mod)
        @events.record([:mouseScroll,   {:x => x, :y => y, :dx => dx, :dy => dy, :mod => mod}])
    end

    def dnd_drop(data)
        # for now, we only support dropping files
        filetype = nil;

        # filetype "osc" currently not supported, as the OSC file loader
        # is not safe against buffer overflow attacks
        ["xmz", "xiz", "xlz", "xsz", "scl", "kbm", "xpz"].each do |i|
            if data.end_with?i then
                filetype = i;
                break;
            end
        end

        if filetype then
            puts("attempting to load " + filetype + "-file " + data + " ...")
            if filetype == "xpz" then
                log(:warning, "Filetype \"" + filetype + "\" not supported yet")
            else
                # not sure which of them will work...
                $remote.action("/load_" + filetype, data)
            end
        end
    end

    def dnd_pick
        aw = activeWidget
        if(aw.respond_to?(:extern))
            return aw.extern
        else
            return ""
        end
    end

    def get_remote_url
        return "osc.udp://" + $remote.getaddr + ":" + $remote.getport.to_s
    end

    def load_event_seq
        @events.reload File.open("/tmp/zest-event-log.txt", "r")
    end

    def handle_events
        cnt = 0
        @events.ev.each do |ev|
            cnt += 1
            GL::debug "handling #{ev}"
            if(ev[0] == :mousePress)
                mouse = MouseButton.new(ev[1][:button], Pos.new(@mx, @my), ev[1][:mod])
                handleMousePress(mouse)
            elsif(ev[0] == :mouseRelease)
                mouse = MouseButton.new(ev[1][:button], Pos.new(@mx, @my), ev[1][:mod])
                handleMouseRelease(mouse)
            elsif(ev[0] == :mouseMove)
                handleCursorPos(ev[1][:x],ev[1][:y],ev[1][:mod])
            elsif(ev[0] == :mouseScroll)
                scroll = MouseScroll.new(ev[1][:x], ev[1][:y], ev[1][:dx], ev[1][:dy], ev[1][:mod])
                handleScroll(ev[1][:x],ev[1][:y], scroll)
            elsif(ev[0] == :windowResize)
                next if @w == ev[1][:w] && @h == ev[1][:h]
                @pending_resize = [ev[1][:w], ev[1][:h]]
                #puts "resize pending... #{1000*(Time.new-@resize_start)}"
                @window.refresh
            end
        end

        #print "E#{cnt}" if cnt != 0
        @events.next_frame
        cnt
    end

    def forget_all_state
        # Explicity require Zest UI to update itself.
        # Invoke this method when user changes a preset in VST host.
        $remote.damage("/")
    end

    ########################################
    #      Widget Hotloading Support       #
    ########################################
    def hotload=(val)
        @hotload = val
    end

    #Setup widget graph
    def doSetup(wOld, wNew)
        if(wNew.respond_to? :onSetup)
            wNew.onSetup(wOld)
        end
        n = wNew.children.length
        m = wOld.nil? ? 0 : wOld.children.length
        (0...n).each do |i|
            if(i<m)
                doSetup(wOld.children[i], wNew.children[i])
            else
                doSetup(nil, wNew.children[i])
            end
        end
    end

    #Merge old widget
    def doMerge(wOld, wNew)
        if(wNew.respond_to? :onMerge)
            wNew.onMerge(wOld)
        end
        n = [wNew.children.length,wOld.children.length].min
        (0...n).each do |i|
            doMerge(wOld.children[i], wNew.children[i])
        end
    end

    def handle_pending_layout
        if(@pending_layout)
            perform_layout
            @draw_seq.make_draw_sequence(@widget)
            @draw_seq.damage_region(DrawRect.new(0, 0, @w, @h), 0)
            @pending_layout = false
        end
    end

    def handle_pending_resize
        return if @pending_resize.nil?
        #puts "handling pending resize = #{1000*(Time.new-@resize_start)}"
        @events.ignore
        @window.w    = @pending_resize[0]
        @window.h    = @pending_resize[1]
        #puts "[INFO] doing a resize to #{@pending_resize}"

        @w = @widget.w  = @pending_resize[0]
        @h = @widget.h  = @pending_resize[1]

        #Layout Widgets again
        perform_layout
        #Build Draw order
        @draw_seq.make_draw_sequence(@widget)
        #Reset textures
        build_fbo

        @draw_seq.damage_region(DrawRect.new(0,0,@widget.w, @widget.h), 0)
        @draw_seq.damage_region(DrawRect.new(0,0,@widget.w, @widget.h), 1)
        @draw_seq.damage_region(DrawRect.new(0,0,@widget.w, @widget.h), 2)
        @pending_resize = nil
        #puts "final time = #{1000*(Time.new-@resize_start)}"

    end

        
    def draw
        #return if !@window.get_refresh
        #puts "drawing..."
        handle_pending_resize
        handle_pending_layout
        #Setup Profilers
        p_total = TimeProfile.new
        p_draw  = TimeProfile.new

        #print 'D'
        #STDOUT.flush

        p_total.start

        w = @window.w
        h = @window.h

        fbo = [@background_fbo, @animation_fbo, @overlay_fbo, @redraw_fbo]

        #Draw the widget tree
        p_draw.time do
            @draw_seq.render(@vg, w, h, fbo)
        end

        p_total.stop
        @window.clear_refresh
    end


    def draw_overlay(w,h,frames)
        #GL::glViewport(0,0,w,h)
        if(h == 1340 && w == 2362 && (1..60).include?(frames%60) && true)
            @vg.draw(w,h,1.0) do |vg|
                power = frames%60
                if(power > 30)
                    power = 60-power
                end
                power /= 30
                pat = vg.image_pattern(0,0,w,h,0,@backdrop,power)
                vg.path do |v|
                    v.rect(0,0,w,h)
                    v.fill_paint(pat)
                    v.fill
                end
            end
        end
    end

    def perform_layout
        if(@widget.respond_to?(:layout))
            #puts "performing layout for widget <#{@widget.w},#{@widget.h}>"
            srt = Time.new
            l = Layout.new
            bounds = l.genConstBox(0, 0, @widget.w, @widget.h, @widget)
            bb = @widget.layout(l,bounds)
            setup = Time.new
            #l.solve
            solve = Time.new

            #Now project the solution onto all widget's that provided bounding
            #boxes
            l.boxes.each do |box|
                #puts "RESULT - <#{box.info.class}, #{box.x}, #{box.y}, #{box.w}, #{box.h}>"
                next if box.info.nil?
                box.info.x = box.x
                box.info.y = box.y
                box.info.w = box.w
                box.info.h = box.h
            end
            fin = Time.new
            #puts "[PERF] Layout: Setup(#{1e3*(setup-srt)}) Solve(#{1e3*(solve-setup)}) Apply(#{1e3*(fin-solve)}) Total #{1000*(fin-srt)}ms"
            #exit
        end
    end

    def animate_frame(widget)
        @draw_seq.animate_frame
    end

    def rec_clean_cbs(widget)
        if(widget.respond_to? :valueRef)
            v = widget.valueRef
            if(v.class == Array)
                v.each do |vv|
                    vv.clean
                end
            else
                v.clean if v.respond_to? :clean
            end
        end
        widget.children.each do |ch|
            rec_clean_cbs(ch)
        end
    end

    def try_hotload(frames, p_code, block)
        return if !@hotload
        nwidget = nil

        #Attempt A code hot swap
        if((frames%10) == 0 && @hotload)
            nwidget = block.call
            begin
                #Try to hotswap common draw routines
                q = "src/mruby-zest/mrblib/draw-common.rb"
                draw_id = File::Stat.new(q).ctime.to_s
                @common_draw_id ||= draw_id
                if(draw_id != @common_draw_id)
                    f = File.read q
                    eval(f)
                    @draw_seq.damage_region(DrawRect.new(0, 0, @w, @h), 0)
                    @common_draw_id = draw_id
                end
            rescue
               GL::debug "Error loading draw common routines"
            end
        end

        #Attempt to merge old widget's runtime values into new widget tree
        #tic = Time.new
        if(nwidget)
            nwidget.parent = self
            nwidget.w = @widget.w
            nwidget.h = @widget.h
            doSetup(@widget, nwidget)
            doMerge(@widget, nwidget)
            rec_clean_cbs(@widget)
            @widget = nwidget
        end
        #t_setup = Time.new

        #Layout Widgets again
        #Build Draw order
        #t_layout_before = Time.new
        if(nwidget)
            perform_layout
            @draw_seq.make_draw_sequence(@widget)
        end
        #t_layout_after = Time.new

        if(nwidget)
            @draw_seq.damage_region(DrawRect.new(0, 0, @w, @h), 0)
            @draw_seq.damage_region(DrawRect.new(0, 0, @w, @h), 1)
            @draw_seq.damage_region(DrawRect.new(0, 0, @w, @h), 2)
            #toc = Time.new
            #puts "[PERF] reload time #{1000*(toc-tic)}ms"
            #puts "[PERF] setup time #{1000*(t_setup-tic)}ms"
            #puts "[PERF] layout time #{1000*(t_layout_after-t_layout_before)}ms"
            @window.refresh
        end
        GC.start
    end

    def check_redraw
        @window.get_refresh
    end

    def tick_remote
        $remote.tick
        last = $remote.last_up_time
        if(last > 2 && last < 50)
            log(:warning, "connection to remote zyn lost")
        end
        nil
    end

    def tick_animation
        now = Time.new
        if(now > @animate_frame_next)
            @animate_frame_next += @animate_frame_dt
            animate_frame @widget
        end

        if(GL::demo_mode)
            if((now-@startup_time) > 10*60)
                $remote.action("/Panic")
                log(:warning, "Demo time is complete")
            end
        end

        nil
    end

    def tick_events
        handle_events
        #if(@quit_time && @quit_time < Time.new)
        #    exit
        #end
        nil
    end

    def tick_hotload(block)
        @hotload_frames ||= 0
        try_hotload(@hotload_frames, nil, block)
        @hotload_frames += 1
        nil
    end

    def tick_sched
        $sched.tick(self) if($sched)
    end

    def doRun(block)
        puts "[INFO] initial qml compile"
        @widget = block.call
        if(@widget.nil?)
            puts "[ERROR] invalid widget creation, try checking those .qml files for a bug"
        end
        @widget.parent = self
        @keep_running = true
        setup


        #Setup Profilers
        p_total = TimeProfile.new
        p_code  = TimeProfile.new
        p_swap  = TimeProfile.new
        p_poll  = TimeProfile.new
        #print '..'

        #Do initial draw
        @draw_seq.damage_region(Rect.new(0, 0, @w, @h), 0)

        last = Time.new
        frames = 0
        while(@window != nil && @keep_running)
            now = Time.new
            if(now > last+200e-3)
                puts
                puts("[WARNING] xrun #{1000*(now-last)} ms")
            end
            last = now

            #print '.'
            #STDOUT.flush

            p_total.start

            p_poll.time do
                $remote.tick

                now = Time.new
                ani = false
                if(now > @animate_frame_next)
                    ani = true
                    @animate_frame_next += @animate_frame_dt
                    animate_frame @widget
                end

                if(!ani && handle_events == 0)
                    sleep 0.02
                end
            end
            frames += 1

            try_hotload(frames, p_code, block)

            p_swap.time do
                @window.poll
            end

            p_total.stop
        end

        if(@window.should_close || true)
            @window.destroy
            @window = nil
            #@events.dump File.open("/tmp/zest-event-log.txt", "w+")
        end
        nil
    end

    ############################################################################
    #                 API For Running Widgets                                  #
    ############################################################################

    attr_accessor :fine_mode, :learn_mode, :reset_mode

    #Force a draw sequence regeneration
    def smash_draw_seq()
        return if @pending_layout
        @draw_seq.make_draw_sequence(@widget)
    end

    #Force a layout regeneration
    def smash_layout()
        @pending_layout = true
        damage_item(@widget, true)
        @window.refresh
    end

    #Damage
    def damage_item(item, all=nil)
        node = @draw_seq.get_node(item)
        #puts "damage_item = #{node.inspect}"
        return if node.nil?
        dmg = DrawRect.new(node.x.to_i,node.y.to_i-0.5,
                           node.w.to_i+0.5,node.h.to_i)
        @draw_seq.damage_region(dmg,  node.layer)
        @draw_seq.damage_region(dmg,  1) if all
        @draw_seq.damage_region(dmg,  2) if all
    end

    def ego_death(item)
        return if item.nil?
        return if item.parent.nil?
        #Remove from parent's children list and perhaps mark properties as no
        #longer in use?
        #Regenerate the draw sequence as a result
        par = item.parent
        chd = par.children
        chd = chd.delete_if {|i| i==item}
        par.children = chd
        damage_item(item)
        smash_draw_seq
        item.parent = nil
    end

    def log(message_class, message, src=:unknown)
        #if(message_class == :user_value)
        #    puts "[LOG#value] #{message.to_s}"
        #else
        #    puts "[LOG#misc]  #{message.to_s}"
        #end
        if(@log_widget)
            @log_widget.display_log(message_class, message.to_s, src)
        end
    end

    def log_widget=(widget)
        @log_widget = widget
        if(!@log_widget.respond_to?(:display_log))
            raise "Invalid logger widget provided to ZRunner"
        end
    end

    def set_view_pos(sym, val)
        @view_pos[sym] = val
    end

    def get_view_pos(sym)
        @view_pos[sym]
    end

    def change_view(w=@widget, level=0)
        #t1 = Time.new if w.respond_to? :set_view
        w.set_view if w.respond_to? :set_view
        w.children.each do |ch|
            change_view(ch, level+1)
        end
        #puts(" "*level + "Change view took #{1000*(t2-t1)} ms @ #<#{w.class}>") if t1
    end

    def set_modal(w)
        if(@modal)
            ego_death(@modal)
        end
        @modal = w
    end

    def animation_fps=(v)
        @animate_frame_dt = 1.0/v
    end
    
    def run_script(x)
        $sched = Sched.new
        sched = $sched
        eval(x)
    end

    def filter_widgets(w=nil, &block)
        out   = []
        w   ||= @widget

        out << w if(block.call(w))

        w.children.each do |ww|
            tmp = filter_widgets(ww, &block)
            if(tmp)
                tmp.each do |t|
                    out << t
                end
            end
        end
        out
    end

    def joint_bounding_box(wid)
        x1 = 99999999.0
        y1 = 99999999.0
        x2 = -1.0
        y2 = -1.0

        wid.each do |ww|
            x = ww.global_x
            y = ww.global_y
            #puts "   y1= #{y}"
            #puts "   y2= #{y+ww.h}"
            x1 = [x1, x].min
            y1 = [y1, y].min
            x2 = [x2, x+ww.w].max
            y2 = [y2, y+ww.h].max
        end
        x1 = x1.floor
        y1 = y1.floor
        w  = (x2-x1).ceil
        h  = (y2-y1).ceil
        #y1 = y2.ceil
        return nil if(x1 > 100000)

        #puts [x1, y1, w, h]
        [x1, y1, w, h]
    end


    def screenshot(x, bb=nil)
        #puts "I would like to take a screenshot and save it to #{x}"
        if(bb)
            #Adjust coords due to flipped y representation
            yt = @h-bb[3]
            bb[1] = yt-bb[1]
            $vg.screenshot(bb[0],
                           bb[1],
                           bb[2],
                           bb[3],
                           x)
        else
            $vg.screenshot(0,0,@w,@h, x)
        end
    end

end


module GL
    class PUGL
        attr_accessor :w, :h
    end
end

module Kernel
    def self.disable_kernel_io
        def print(*args)
        end
        def puts(*args)
        end
        def printf(*args)
        end
        def gets(*args)
        end
        def getc(*args)
        end
    end
end
    
def disable_kernel_io
    Kernel.disable_kernel_io
    def print(*args)
    end
    def puts(*args)
    end
    def printf(*args)
    end
    def gets(*args)
    end
    def getc(*args)
    end
end
