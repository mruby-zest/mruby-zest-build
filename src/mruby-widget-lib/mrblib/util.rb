def limit(x, low, high)
    if(x>high)
        high
    elsif(x<low)
        low
    else
        x
    end
end

module Modifiers
    SHIFT   = 1
    CTRL    = 2
    ALT     = 4
    SUPER   = 8

    def self.get_list_from_int(mod)
        list = []

        list.append(:ctrl)  if(mod & Modifiers::CTRL  != 0)
        list.append(:alt)   if(mod & Modifiers::ALT   != 0)
        list.append(:shift) if(mod & Modifiers::SHIFT != 0)
        list.append(:super) if(mod & Modifiers::SUPER != 0)

        return list
    end
end

class MouseButton
    attr_reader :pos
    attr_reader :buttons
    attr_reader :mod

    def initialize(enum, pos, mod)
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

        @mod = Modifiers::get_list_from_int(mod)
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
