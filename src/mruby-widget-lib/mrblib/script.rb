class ZRunner
    @@first = true

    def initialize
        if(@@first)
            #GLFW.init
            @@first = false
        end
        @events = UiEventSeq.new
        @mx=0
        @my=0
        @clicked=nil
    end

    def draw_seq_add(item, xoff, yoff)
        if(item.respond_to? :draw)
            @draw_seq << DrawSeqNode.new(xoff,yoff,item.w,item.h,item)
        end
    end

    def make_draw_sequence_recur(item, xoff, yoff)
        if(item && xoff && yoff)
            draw_seq_add(item, xoff, yoff)
            item.children.each do |ch|
                if(ch.y && ch.x)
                    make_draw_sequence_recur(ch, xoff+ch.x, yoff+ch.y)
                else
                    puts "bad x/y"
                    puts "widget = <#{ch}>"
                end
            end
        end
    end

    def make_draw_sequence(root)
        @draw_seq = []
        make_draw_sequence_recur(root, 0, 0)
    end

    def run_draw_sequence(vg,w,h)
        #puts "running draw sequence on #{w}x#{h} window"
        GL::gl_viewport(0, 0, w, h);
        GL::gl_clear_color(0, 0, 0, 1.0);
        GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

        GL::gl_viewport(0, 0, w, h);
        vg.draw(w,h,1.0) do |v|
            @draw_seq.each do |n|
                v.spork do |vv|
                    vv.translate(n.x,n.y)
                    n.item.draw(vv)
                end
            end
        end
    end

    #holds true only in cases of a spacial partitioning
    def activeWidget(mx=@mx, my=@my, xoff=0,yoff=0,scope=@widget)
        if(scope)
            scope.children.each do |ch|
                if(Rect.new(xoff+ch.x, yoff+ch.y, ch.w, ch.h).include(mx, my))
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
        end
        @clicked = Pos.new(@mx,@my)
    end

    def handleMouseRelease(mouse)
        @clicked = nil
    end

    def handleCursorPos(x,y)
        @mx = x
        @my = y
        if(@clicked)
            aw = activeWidget(@clicked.x, @clicked.y)
            if(aw.respond_to? :onMouseMove)
                aw.onMouseMove MouseButton.new(0,Pos.new(x,y))
            end
        end
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

    def init_glfw_callbacks
        puts "init glfw"
        @window.set_mouse_button_callback do |mouse, button, action, mod|
            if(action == 1)
                @events.record([:mousePress,   {:button => button, :action => action, :mod => mod}])
            else
                @events.record([:mouseRelease, {:button => button, :action => action, :mod => mod}])
            end
        end

        @window.set_cursor_pos_callback do |c, x, y|
            @events.record([:mouseMove, {:x => x, :y => y}])
        end

        @window.set_key_callback do |key, a, b, c, d|
            @events.record([:keyPress, {:key => a, :down => c}])
        end

        @window.set_size_callback do |key, w, h|
            @events.record([:windowResize, {:w => w, :h => h}])
        end
    end

    def init_pugl
        puts "init pugl"
        @window = GL::PUGL.new self
        init_gl
        @window.impl = self
    end

    def init_gl
        puts "init gl"
        #@window=GLFW::Window.new(100,600,"Test",nil,nil)
        @window.make_current
        #GLEW.init
        #@window.swap_buffers
        @w,@h=*@window.size

        #GLEW.init
        @vg=NVG::Context.new(NVG::ANTIALIAS | NVG::STENCIL_STROKES | NVG::DEBUG)
        $vg = @vg

        #Load Fonts
        sans = `find . -type f | grep Regular.ttf`.split[0]
        @vg.create_font('sans', sans)
        bold = `find . -type f | grep Bold.ttf`.split[0]
        @vg.create_font('bold', bold)
        @backdrop = @vg.create_image('../template.png', 0)
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
        #puts "window.w = <#{w}>"

        #Draw the widget tree
        p_draw.time do
            run_draw_sequence(@vg, w, h)
        end

        #Draw Overlay
        #draw_overlay(w,h,frames)

        p_total.stop

        #puts ObjectSpace.count_objects.keys
        #puts ObjectSpace.count_objects.values
        #puts "#{frames}, #{p_total.avg_hz.to_i}Hz, #{p_total.avg}, #{p_draw.avg}, #{p_code.avg}, #{1000.0/60.0}"
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

    def load_event_seq
        @events.reload File.open("/tmp/zest-event-log.txt", "r")
    end

    $resize_count = 0
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
                $resize_count += 1
                #if($resize_count < 10)
                @events.ignore
                @window.size = [ev[1][:w], ev[1][:h]]
                puts "doing a resize to #{[ev[1][:w], ev[1][:h]]}"

                @widget.w  = ev[1][:w]
                @widget.h  = ev[1][:h]

                #Layout Widgets again
                #Build Draw order
                perform_layout
                make_draw_sequence(@widget)
                #end
            end
        end

        @events.next_frame
        cnt
    end

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
            @widget.w,@widget.h = [512, 512]#@window.size
        #end

        doSetup(nil, @widget)

        perform_layout
        make_draw_sequence(@widget)

        @widget.db.make_rdepends
        puts "Widget setup..."
        #puts @widget.db
    end

    def doRun(&block)
        @widget = block.call
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

        frames = 0
        while(frames < 100000 && @window != nil && @keep_running)
            print '.'
            STDOUT.flush

            p_total.start

            p_poll.time do
                if(handle_events == 0)
                    sleep 0.02
                end
            end
            frames += 1

            if(true)
                nwidget = nil

                #Attempt A code hot swap
                p_code.time do
                    nwidget = block.call
                end

                #Attempt to merge old widget's runtime values into new widget tree
                tic = Time.new
                if(nwidget)
                    doSetup(@widget, nwidget)
                    doMerge(@widget, nwidget)
                    nwidget.parent = self
                    nwidget.w = @widget.w
                    nwidget.h = @widget.h
                    @widget = nwidget
                end
                t_setup = Time.new

                #sizeChange = @window.size != [@widget.w, @widget.h]
                #locsChange = nwidget || sizeChange

                ##Update main window size
                #if(sizeChange)
                #    @widget.w, @widget.h  = @window.size
                #end

                #Layout Widgets again
                #Build Draw order
                t_layout_before = Time.new
                if(nwidget)
                    perform_layout
                    make_draw_sequence(@widget)
                end
                t_layout_after = Time.new

                if(nwidget)
                    toc = Time.new
                    puts "reload time #{1000*(toc-tic)}ms"
                    puts "setup time #{1000*(t_setup-tic)}ms"
                    puts "layout time #{1000*(t_layout_after-t_layout_before)}ms"
                end
                @window.refresh
            end

            p_swap.time do
                @window.poll
            end

            p_total.stop

            #puts ObjectSpace.count_objects.keys
            #puts ObjectSpace.count_objects.values
            #puts "#{frames}, #{p_total.avg_hz.to_i}Hz, #{p_total.avg}, #{p_draw.avg}, #{p_code.avg}, #{1000.0/60.0}"
        end

        if(@window.should_close || true)
            @window.destroy
            @window = nil
            #@events.dump File.open("/tmp/zest-event-log.txt", "w+")
        end
        nil
    end
end


module GL
    class PUGL
        attr_accessor :w, :h
    end
end
