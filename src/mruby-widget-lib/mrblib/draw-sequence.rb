class DrawSeqNode
    attr_reader :x, :y, :w, :h, :item, :layer
    def initialize(x,y,item)
        @x     = x
        @y     = y
        @w     = item.w
        @h     = item.h
        @item  = item
        @layer = item.layer
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
            @seq << DrawSeqNode.new(xoff, yoff, item)
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
        (0..2).each do |layer_id|
            selected_fbo = nil
            if(layer_id == 0)
                selected_fbo = background_fbo
            elsif(layer_id == 1)
                selected_fbo = animation_fbo
            elsif(layer_id == 2)
                selected_fbo = overlay_fbo
            end

            redraw_fbo.select
            #puts "running draw sequence on #{w}x#{h} window"
            GL::gl_viewport(0, 0, w, h);
            GL::gl_clear_color(0, 0, 0, 0.0);
            GL::gl_clear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);

            GL::gl_viewport(0, 0, w, h);
            vg.draw(w,h,1.0) do |v|
                @seq.each do |n|
                    if(n.layer == layer_id)
                        v.spork do |vv|
                            vv.translate(n.x,n.y)
                            n.item.draw(vv)
                        end
                    end
                end
            end
            selected_fbo.select

            #puts @damage
            @damage.each do |dmg|
                d = dmg[0]
                GL::gl_viewport(0,0,w,h)
                GL::gl_scissor(d.x, h-(d.y+d.h), d.w, d.h)
                GL::gl_clear_color(0, 0, 0, 0.0)
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

        @damage = []
    end

    def get_image(fbo)
        im = fbo.image $vg
        Nanovg::ImageHandle.new($vg, im)
    end


    private :make_draw_sequence_recur

end
