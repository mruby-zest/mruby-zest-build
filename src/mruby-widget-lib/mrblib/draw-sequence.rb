class DrawRect
    attr_reader :x, :y, :w, :h

    def to_s
        "<DrawRect x:#{@x} y:#{@y} w:#{@w} h:#{@h}>"
    end
    def inspect
        to_s
    end
end

class DrawSeqNode
    attr_reader :x, :y, :w, :h, :item, :layer
    #def initialize(x,y,item)
    #    @x     = x.to_i
    #    @y     = y.to_i
    #    @w     = item.w.to_i
    #    @h     = item.h.to_i
    #    @item  = item
    #    @layer = item.layer
    #end

    #def hit?(x,y)
    #    hx = @x <= x && x <= @x+@w
    #    hy = @y <= y && y <= @y+@h
    #    hx && hy
    #end

    #def intersect?(dmg)
    #    (rect, layer) = dmg
    #    if(layer == @layer)
    #        return GL::intersect(rect.x, rect.y, rect.w, rect.h, @x, @y, @w, @h)
    #        #left_in  = rect.x       >=@x && rect.x       <=@x+@w
    #        #right_in = rect.x+rect.w>=@x && rect.x+rect.w<=@x+@w
    #        #lr_in    = rect.x       <=@x && rect.x+rect.w>=@x+@w

    #        #top_in   = rect.y       >=@y && rect.y       <=@y+@h
    #        #bot_in   = rect.y+rect.h>=@y && rect.y+rect.h<=@y+@h
    #        #tb_in    = rect.y       <=@y && rect.y+rect.h>=@y+@h

    #        #(left_in || right_in || lr_in) && (top_in || bot_in || tb_in)
    #    else
    #        false
    #    end
    #end

    def to_s
        "<DrawSeqNode x:#{@x} y:#{@y} w:#{@w} h:#{@h} layer:#{@layer} cls:#{@item.class}>"
    end
    def inspect
        to_s
    end
end

class DrawSequence
    attr_accessor :window, :damage, :seq
    def initialize_rb
        @damage        = []
        @damage_layers = []
        @seq           = []
        @animated      = nil
    end

    def animate_frame
        #Rebuild animation list as needed
        if(@animated.nil?)
            @animated = []
            @seq.each do |s|
                @animated << s.item if s.item.respond_to?(:animate)
            end
        end
        @animated.each do |a|
            a.animate
        end
    end

    # Force a redraw in the given region
    def damage_region(region, layer)
        if(@damage != :everything)
            @damage << [region, layer]
        end
        @damage_layers << layer
        @window.refresh
    end

    # Add a widget to the draw sequence
    def add(item, xoff, yoff)
        if(item.respond_to? :draw)
            node = DrawSeqNode.new(xoff, yoff, item)
            @seq << node
            add_seq_c(node)
        end
    end

    def make_draw_sequence_recur(item, xoff, yoff)
        xoff = xoff.to_i
        yoff = yoff.to_i
        if(item && xoff && yoff)
            add(item, xoff, yoff)
            item.children.each do |ch|
                #puts "        Box = <#{ch.class}, #{ch.x.inspect},#{ch.y.inspect},#{ch.w.inspect},#{ch.h.inspect}>"
                if(ch.y && ch.x)
                    make_draw_sequence_recur(ch, xoff+ch.x, yoff+ch.y)
                else
                    puts "[ERROR] X/Y Are Nil"
                    puts "        Relative bounding box = <#{ch.x.inspect},#{ch.y.inspect},#{ch.w.inspect},#{ch.h.inspect}>"
                    puts "        widget.class = <#{ch.class}>"
                    puts "        widget       = <#{ch}>"
                end
            end
        end
    end

    def make_draw_sequence(root)
        #puts "[DEBUG] Make Draw Sequence"
        @seq = []
        clear_seq_c
        @animated = nil
        make_draw_sequence_recur(root, 0, 0)
    end

    #Run the full draw sequence
    def render(vg, w, h, fbo)
        (background_fbo, animation_fbo, overlay_fbo, redraw_fbo) = fbo
        drawn_widgets = 0
        if(false)
            puts background_fbo
            puts animation_fbo
            puts overlay_fbo
            puts redraw_fbo
        end
        #[@background_fbo, @animation_fbo, @overlay_fbo, @redraw_fbo].each do |fbo|
        #    fbo.select
        #    GL::gl_viewport(0, 0, w, h);
        #    GL::gl_clear_color(0, 0, 0, 1.0);
        #    GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
        #end
        rseq = render_seqs()
        (0..2).each do |layer_id|
            updating_layer = @damage_layers.include?(layer_id)
            next if !updating_layer

            selected_fbo = nil
            if(layer_id == 0)
                selected_fbo = background_fbo
            elsif(layer_id == 1)
                selected_fbo = animation_fbo
            elsif(layer_id == 2)
                selected_fbo = overlay_fbo
            end

            redraw_fbo.select
            #puts "running draw sequence on #{w}x#{h} window layer=#{layer_id}"
            GL::gl_viewport(0, 0, w, h);
            GL::gl_clear_color(0, 0, 0, 0.0);
            GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

            GL::gl_viewport(0, 0, w, h);
            vg.draw(w,h,1.0) do
                rseq[layer_id].each do |n|
                    drawn_widgets += 1
                    vg.spork do
                        vg.translate(n.x,n.y)
                        n.item.draw(vg)
                    end
                end
            end
            selected_fbo.select

            #puts @damage
            @damage.each do |dmg|
                next if(dmg[1] != layer_id)
                d = dmg[0]
                GL::gl_viewport(0,0,w,h)
                GL::gl_scissor(d.x, h-(d.y+d.h), d.w, d.h)
                GL::gl_clear_color(0, 0, 0, 0.0)
                GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
                GL::gl_scissor_end
            end


            redraw_img = get_image(redraw_fbo)
            #@damage = [[DrawRect.new(0, 0, 512,512)]]

            GL::gl_viewport(0, 0, w, h);
            vg.draw(w, h, 1.0) do |v|
                @damage.each do |dmg|
                    next if(dmg[1] != layer_id)
                    d = dmg[0]
                    pat = vg.image_pattern(0,h,w,h,0,redraw_img.image, 1.0)
                    vg.path do |p|
                        p.rect(d.x-0.5,d.y+0.5,d.w,d.h)
                        v.fill_paint pat
                        v.fill
                    end
                end
            end
        end

        # Composite the layers
        layers = []
        layers << get_image(background_fbo)
        layers << get_image(animation_fbo)
        layers << get_image(overlay_fbo)
        redraw_fbo.deselect

        GL::gl_viewport(0, 0, w, h);
        GL::gl_clear_color(0, 0, 0, 1.0)
        GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

        vg.draw(w, h, 1.0) do |v|
            layers.each do |img|
                pat = vg.image_pattern(0,h,w,h,0,img.image, 1.0)
                vg.path do |p|
                    p.rect(0, 0, w, h)
                    v.fill_paint pat
                    v.fill
                end
            end
        end

        #print drawn_widgets
        @damage_layers = []
        @damage        = []
    end

    def get_image(fbo)
        im = fbo.image $vg
        Nanovg::ImageHandle.new($vg, im)
    end


    #Find a widget which should accept a particular event
    # - Widgets which are drawn later take higher precedence
    # - Widgets drawn on the animation layer cannot receive events
    # - Widgets drawn on the overlay layer take precedence over the ground layer
    #
    # inputs:
    # - x location relative to the root of the window
    # - y location relative to the root of the window
    # - optional method which widget must respond to
    #  (filters out decoration widgets)
    #def event_widget(x, y, method=nil)
    #    selected_item  = nil
    #    selected_layer = 0
    #    @seq.each do |elm|
    #        next if elm.layer == 1
    #        next if selected_layer == 2 && elm.layer != 2
    #        next if !method.nil? && !elm.item.respond_to?(method)
    #        if(elm.hit?(x,y))
    #            selected_item  = elm.item
    #            selected_layer = elm.layer
    #        end
    #    end
    #    selected_item
    #end
    
    #Similar to event_widget, but does not have the x/y hit detection
    def find_widget(method)
        selected_item  = nil
        selected_layer = 0
        priority       = 0
        @seq.each do |elm|
            next if elm.layer == 1
            next if selected_layer == 2 && elm.layer != 2
            next if !elm.item.respond_to?(method)
            epri = elm.item.respond_to?(:priority) ? elm.item.priority : 0
            next if epri < priority

            selected_item  = elm.item
            selected_layer = elm.layer
            priority       = epri
        end
        selected_item
    end

    private :make_draw_sequence_recur

end
