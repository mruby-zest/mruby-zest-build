def limit(x, low, high)
    if(x>high)
        high
    elsif(x<low)
        low
    else
        x
    end
end

class MouseButton
    attr_reader :pos
    attr_reader :buttons
    def initialize(enum, pos)
        @pos = pos
        if(enum == 1)
            @buttons = [:leftButton]
        elsif(enum == 2)
            @buttons = [:middleButton]
        elsif(enum == 3)
            @buttons = [:rightButton]
        elsif(enum == 4)
            @buttons = [:drag_and_drop]
        else
            @buttons = []
        end
    end
end

#module GL
#    extend FFI::Library
#    ffi_lib 'libGL.so'
#    attach_function :glClear, [:int], :void
#    attach_function :glViewport, [:int,:int,:int,:int], :void
#    attach_function :glClearColor, [:float, :float, :float, :float], :void
#end

GL_COLOR_BUFFER_BIT   = 0x00004000
GL_DEPTH_BUFFER_BIT   = 0x00000100
GL_STENCIL_BUFFER_BIT = 0x00000400
