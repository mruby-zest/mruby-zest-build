#Layers
#-1 - merged     layer
# 0 - background layer
# 1 - animation  layer
# 2 - overlay    layer

class ZRunner
    def initialize
        @events   = UiEventSeq.new
        @draw_seq = DrawSequence.new
        @mx       = 0
        @my       = 0
        @clicked  = nil

        #Framebuffers
        @background_fbo = nil
        @animation_fbo  = nil
        @overlay_fbo    = nil
        @redraw_fbo     = nil

        @background_img = nil
        @animation_img  = nil
        @overlay_img    = nil
        @redraw_img     = nil

        #global stuff?
        $remote = OSC::Remote.new
        print "remote = "
        puts $remote
    end

    ########################################
    #       Graphics Init Routines         #
    ########################################

    def setup
        puts "setup..."
        if(!@widget)
            puts "No Widget was allocated"
            puts "This is typically a problem with running the code from the wrong subdirectory"
            puts "If mruby-zest cannot find the qml source files, then the UI cannot be created"
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
        puts "Widget setup..."
        #puts @widget.db
    end

    def init_pugl
        puts "init pugl"
        @window = GL::PUGL.new self
        @draw_seq.window = @window
        init_gl
        @window.impl = self
    end

    def init_gl
        puts "init gl"
        @window.make_current
        @window.size = [1181,659]
        @w,@h=*@window.size
        @w = 1181
        @h = 659

        @vg     = NVG::Context.new(NVG::ANTIALIAS | NVG::STENCIL_STROKES | NVG::DEBUG)

        #Global Initialize
        $vg     = @vg

        #Load Fonts
        sans = `find . -type f | grep Regular.ttf`.split[0]
        @vg.create_font('sans', sans)
        bold = `find . -type f | grep Bold.ttf`.split[0]
        @vg.create_font('bold', bold)

        #Load Overlay image
        @backdrop = @vg.create_image('../template.png', 0)
        puts "window width=#{@w}"
        puts "window height=#{@h}"

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
    def activeWidget(mx=@mx, my=@my, xoff=0,yoff=0,scope=@widget)
        if(scope && scope.layer != 1)
            scope.children.each do |ch|
                if(Rect.new(xoff+ch.x, yoff+ch.y, ch.w, ch.h).include(mx, my) && ch.layer != 1)
                    out = activeWidget(mx, my, xoff+ch.x, yoff+ch.y, ch);
                    return out if out
                end
            end
            return scope
        end
        nil
    end

    def handleMousePress(mouse)
        aw = activeWidget
        puts "active widget = #{aw}"
        if(aw.respond_to? :onMousePress)
            puts "mouse press = #{mouse.pos}"
            aw.onMousePress mouse
        else
            puts "no mouse press option..."
        end
        @window.refresh
        @clicked = Pos.new(@mx,@my)
    end

    def handleMouseRelease(mouse)
        @clicked = nil
    end

    def handleCursorPos(x,y)
        old_aw = activeWidget(@mx, @my)
        @mx = x
        @my = y
        if(@clicked)
            aw = activeWidget(@clicked.x, @clicked.y)
            if(aw.respond_to? :onMouseMove)
                aw.onMouseMove MouseButton.new(0,Pos.new(x,y))
            end
        else
            aw = activeWidget(x, y)
            if(aw.respond_to? :onMouseHover)
                aw.onMouseHover MouseButton.new(0,Pos.new(x,y))
            end
            if(aw != old_aw && aw.respond_to?(:onMouseEnter))
                aw.onMouseEnter MouseButton.new(0,Pos.new(x,y))
            end
        end
    end

    def quit
        @keep_running = false
    end

    def resize(w,h)
        @events.record([:windowResize, {:w => w, :h => h}])
    end

    def cursor(x,y)
        @events.record([:mouseMove, {:x => x, :y => y}])
    end

    def mouse(button, action, x, y)
        mod = nil
        if(action == 1)
            @events.record([:mousePress,   {:button => button, :action => action, :mod => mod}])
        else
            @events.record([:mouseRelease, {:button => button, :action => action, :mod => mod}])
        end
    end

    def load_event_seq
        @events.reload File.open("/tmp/zest-event-log.txt", "r")
    end

    def handle_events
        cnt = 0
        @events.ev.each do |ev|
            cnt += 1
            #puts "handling #{ev}"
            if(ev[0] == :mousePress)
                mouse = MouseButton.new(ev[1][:button], Pos.new(@mx, @my))
                handleMousePress(mouse)
            elsif(ev[0] == :mouseRelease)
                mouse = MouseButton.new(ev[1][:button], Pos.new(@mx, @my))
                handleMouseRelease(mouse)
            elsif(ev[0] == :mouseMove)
                handleCursorPos(ev[1][:x],ev[1][:y])
            elsif(ev[0] == :windowResize)
                @events.ignore
                @window.size = [ev[1][:w], ev[1][:h]]
                puts "doing a resize to #{[ev[1][:w], ev[1][:h]]}"

                @w = @widget.w  = ev[1][:w]
                @h = @widget.h  = ev[1][:h]

                #Layout Widgets again
                perform_layout
                #Build Draw order
                @draw_seq.make_draw_sequence(@widget)
                #Reset textures
                build_fbo

                @draw_seq.damage_region(Rect.new(0,0,@widget.w, @widget.h), 0)
                @draw_seq.damage_region(Rect.new(0,0,@widget.w, @widget.h), 1)
                @draw_seq.damage_region(Rect.new(0,0,@widget.w, @widget.h), 2)
            end
        end

        @events.next_frame
        cnt
    end

    ########################################
    #      Widget Hotloading Support       #
    ########################################

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

    def draw
        #Setup Profilers
        p_total = TimeProfile.new
        p_draw  = TimeProfile.new

        print '.'
        STDOUT.flush

        p_total.start

        w = @window.w
        h = @window.h

        fbo = [@background_fbo, @animation_fbo, @overlay_fbo, @redraw_fbo]

        #Draw the widget tree
        p_draw.time do
            @draw_seq.render(@vg, w, h, fbo)
        end

        p_total.stop
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
            srt = Time.new
            #puts "Layout Start..."
            l = Layout.new
            bb = @widget.layout l
            puts bb
            if(bb)
                l.sh([bb.x], [1], 0)
                l.sh([bb.y], [1], 0)
                l.sh([bb.x, bb.w], [1, 1], @widget.w)
                l.sh([bb.y, bb.h], [1, 1], @widget.h)
            end
            setup = Time.new
            l.solve
            solve = Time.new
            #puts "Applying Layout..."

            #Now project the solution onto all widget's that provided bounding
            #boxes
            l.boxes.each do |box|
                if(box.info)
                    #puts "apply <#{l.getR box}>..."
                    box.info.x = l.get box.x
                    box.info.y = l.get box.y
                    box.info.w = l.get box.w
                    box.info.h = l.get box.h
                end
            end
            #puts "Performed Layout..."
            fin = Time.new
            #puts "Time was #{1000*(fin-srt)}ms"
            puts "Layout: Setup(#{1e3*(setup-srt)}) Solve(#{1e3*(solve-setup)}) Apply(#{1e3*(fin-solve)}) Total #{1000*(fin-srt)}ms"
            #exit
        end
    end

    def doRun(&block)
        @widget = block.call
        if(@widget.nil?)
            puts "invalid widget creation, try checking those .qml files for a bug"
        end
        @widget.parent = self
        @keep_running = true
        puts "widget = <#{@widget}>"
        setup

        puts @widget.root

        #Setup Profilers
        p_total = TimeProfile.new
        p_code  = TimeProfile.new
        p_swap  = TimeProfile.new
        p_poll  = TimeProfile.new
        print '..'

        #Do initial draw
        @draw_seq.damage_region(Rect.new(0, 0, @w, @h), 0)

        frames = 0
        while(frames < 100000 && @window != nil && @keep_running)
            print '.'
            STDOUT.flush

            p_total.start

            p_poll.time do
                $remote.tick
                if(handle_events == 0)
                    sleep 0.02
                end
            end
            frames += 1

            if(true)
                nwidget = nil

                #Attempt A code hot swap
                if((frames%10) == 0)
                    p_code.time do
                        nwidget = block.call
                    end
                end

                #Attempt to merge old widget's runtime values into new widget tree
                tic = Time.new
                if(nwidget)
                    nwidget.parent = self
                    nwidget.w = @widget.w
                    nwidget.h = @widget.h
                    doSetup(@widget, nwidget)
                    doMerge(@widget, nwidget)
                    @widget = nwidget
                end
                t_setup = Time.new

                #Layout Widgets again
                #Build Draw order
                t_layout_before = Time.new
                if(nwidget)
                    perform_layout
                    @draw_seq.make_draw_sequence(@widget)
                end
                t_layout_after = Time.new

                if(nwidget)
                    damage_item nwidget
                    toc = Time.new
                    puts "reload time #{1000*(toc-tic)}ms"
                    puts "setup time #{1000*(t_setup-tic)}ms"
                    puts "layout time #{1000*(t_layout_after-t_layout_before)}ms"
                    @window.refresh
                end
            end

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

    #Force a draw sequence regeneration
    def smash_draw_seq()
        @draw_seq.make_draw_sequence(@widget)
    end

    #Damage
    def damage_item(item)
        @draw_seq.seq.each do |dsn|
            if(dsn.item == item)
                @draw_seq.damage_region(Rect.new(dsn.x,dsn.y,dsn.w,dsn.h),item.layer)
            end
        end
    end

    def ego_death(item)
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
        if(message_class == :user_value)
            puts "[LOG#value] #{message.to_s}"
        else
            puts "[LOG#misc]  #{message.to_s}"
        end
        if(@log_widget)
            @log_widget.display_log(message_class, message.to_s, src)
        end
    end

    def log_widget=(widget)
        puts "Setting logging widget to: "
        puts widget
        @log_widget = widget
        if(!@log_widget.respond_to?(:display_log))
            raise "Invalid logger widget provided to ZRunner"
        end
    end
end


module GL
    class PUGL
        attr_accessor :w, :h
    end
end
