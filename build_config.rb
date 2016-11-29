puts "Environment is:"
puts ENV.include? "WINDOWS"
windows = ENV.include? "WINDOWS"
RUBY_PLATFORM = "mingw" if ENV.include? "WINDOWS"

if(windows)
  puts" Setting up host build"
  MRuby::Build.new('host') do |conf|
    toolchain :gcc

    conf.cc do |cc|
      cc.command = 'gcc'
      cc.flags = []
    end
    conf.linker do |linker|
      linker.command = 'gcc'
      linker.flags   = []
    end
    conf.archiver do |archiver|
      archiver.command = 'ar'
    end
    conf.gembox 'default'
  end
end

build_type = MRuby::Build if !windows
build_name = "host"       if !windows

build_type = MRuby::CrossBuild if windows
build_name = "w64"             if windows

build_type.new(build_name) do |conf|
  # load specific toolchain settings

  toolchain :gcc

  enable_debug

  conf.cc.defines = %w(MRUBY_NANOVG_GL2)
  conf.cc.flags << '-O3'

  #No default gems
  # Use standard print/puts/p
  conf.gem :core => "mruby-print"

  # Use standard Math module
  conf.gem :core => "mruby-math"

  # Use standard Time class
  conf.gem :core => "mruby-time"

  # Use String class extension
  conf.gem :core => "mruby-string-ext"

  # Use Proc class extension
  conf.gem :core => "mruby-proc-ext"

  # Use Random class
  conf.gem :core => "mruby-random"

  # Use Object class extension
  conf.gem :core => "mruby-object-ext"

  # Use toplevel object (main) methods extension
  conf.gem :core => "mruby-toplevel-ext"

  # Generate mruby command
  conf.gem :core => "mruby-bin-mruby"

  # Use mruby-compiler to build other mrbgems
  conf.gem :core => "mruby-compiler"

  #Eval for runtime reloads
  conf.gem :core => "mruby-eval"

  #Non-STD lib gems
  conf.gem 'deps/mruby-complex'
  conf.gem 'deps/mruby-io'
  conf.gem 'deps/mruby-nanovg'
  conf.gem 'deps/mruby-sleep'
  conf.gem 'deps/mruby-regexp-pcre'
  conf.gem 'deps/mruby-dir-glob'
  conf.gem 'deps/mruby-set'

  conf.cc do |cc|
      cc.include_paths << "#{`pwd`.strip}/../deps/nanovg/src"
      cc.include_paths << "#{`pwd`.strip}/../deps/pugl/"
      cc.include_paths << "#{`pwd`.strip}/../deps/libuv-v1.9.1/include/"
      cc.include_paths << "/usr/share/mingw-w64/include/" if windows
      cc.include_paths << "/usr/x86_64-w64-mingw32/include/" if windows
      cc.flags << "-std=gnu99 -fPIC"
      cc.flags << "-DWINDOWS_WHY" if windows
      cc.flags << "-mstackrealign" if windows
  end

  conf.linker do |linker|
      #linker.library_paths  << "#{`pwd`.strip}/../deps/nanovg/build/"
      #linker.library_paths  << "#{`pwd`.strip}/../deps/rtosc/build/"
      linker.library_paths  << "#{`pwd`.strip}/../src/osc-bridge/"
      linker.libraries << 'osc-bridge'
      linker.flags_after_libraries  << "#{`pwd`.strip}/../deps/libuv.a"
      linker.flags_after_libraries  << "#{`pwd`.strip}/../deps/pugl/build/libpugl-0.a"
      linker.flags_after_libraries  << "#{`pwd`.strip}/../deps/librtosc.a"
      linker.flags_after_libraries  << "#{`pwd`.strip}/../deps/libnanovg.a"
      if(!windows)
        linker.libraries << 'GL'
        linker.libraries << 'X11'
        linker.flags_after_libraries  << "-lpthread -ldl"
      else
        linker.flags_after_libraries  << "-lws2_32 -lkernel32 -lpsapi -luserenv -liphlpapi"
        linker.flags_after_libraries  << "-lglu32 -lgdi32 -lopengl32"
      end
  end

  #Custom Gems
  conf.gem 'src/mruby-qml-spawn'
  conf.gem 'src/mruby-qml-parse'
  conf.gem 'src/mruby-zest'
  conf.gem 'src/mruby-layout'

  #Scrap Code Gem
  conf.gem 'src/mruby-widget-lib'

  #Binary Launcher
  #conf.gem 'src/mruby-bin-zest'

end

MRuby::Build.new('host-debug') do |conf|
  # load specific toolchain settings
  toolchain :clang

  enable_debug

  # include the default GEMs
  conf.gembox 'default'

  # C compiler settings
  conf.cc.defines = %w(MRB_ENABLE_DEBUG_HOOK MRUBY_NANOVG_GL2)

  # Generate mruby debugger command (require mruby-eval)
  conf.gem :core => "mruby-bin-debugger"
end
