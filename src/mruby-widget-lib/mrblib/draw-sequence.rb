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

class DrawSequence
    attr_accessor :window, :damage, :seq
    def initialize
        @damage   = []
        @seq      = []
    end

    # Force a redraw in the given region
    def damage_region(region, layer)
        if(@damage != :everything)
            @damage << [region, layer]
        end
        @window.refresh
    end

    # Add a widget to the draw sequence
    def add(item, xoff, yoff)
        if(item.respond_to? :draw)
            @seq << DrawSeqNode.new(xoff,yoff,item.w,item.h,item)
        end
    end

    def make_draw_sequence_recur(item, xoff, yoff)
        if(item && xoff && yoff)
            add(item, xoff, yoff)
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
        @seq = []
        make_draw_sequence_recur(root, 0, 0)
    end

    #Run the full draw sequence
    def render(vg, w, h, fbo)
        (background_fbo, animation_fbo, overlay_fbo, redraw_fbo) = fbo
        puts background_fbo
        puts animation_fbo
        puts overlay_fbo
        puts redraw_fbo
        #[@background_fbo, @animation_fbo, @overlay_fbo, @redraw_fbo].each do |fbo|
        #    fbo.select
        #    GL::gl_viewport(0, 0, w, h);
        #    GL::gl_clear_color(0, 0, 0, 1.0);
        #    GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
        #end
        redraw_fbo.select
        #puts "running draw sequence on #{w}x#{h} window"
        GL::gl_viewport(0, 0, w, h);
        GL::gl_clear_color(0, 0, 0, 1.0);
        GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

        GL::gl_viewport(0, 0, w, h);
        vg.draw(w,h,1.0) do |v|
            @seq.each do |n|
                v.spork do |vv|
                    vv.translate(n.x,n.y)
                    n.item.draw(vv)
                end
            end
        end
        redraw_fbo.deselect

        #puts @damage
        @damage.each do |dmg|
            d = dmg[0]
            GL::gl_viewport(0,0,w,h)
            GL::gl_scissor(d.x, h-(d.y+d.h), d.w, d.h)
            GL::gl_clear_color(0, 0, 0, 1.0)
            GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
            GL::gl_scissor_end
        end


        redraw_img = get_image(redraw_fbo)
        #@damage = [[Rect.new(0, 0, 512,512)]]

        GL::gl_viewport(0, 0, w, h);
        vg.draw(w, h, 1.0) do |v|
            @damage.each do |dmg|
                d = dmg[0]
                pat = vg.image_pattern(0,h,w,h,0,redraw_img.image, 1.0)
                vg.path do |p|
                    p.rect(d.x,d.y,d.w,d.h)
                    v.fill_paint pat
                    v.fill
                end
            end
        end

        @damage = []
    end

    def get_image(fbo)
        im = fbo.image $vg
        Nanovg::ImageHandle.new($vg, im)
    end


    private :make_draw_sequence_recur

end
