puts "Environment is:"
puts ENV['OS']

linux   = RbConfig::CONFIG['host_os'].include? "linux"
windows = ENV.include? "WINDOWS"
mac     = ENV['OS'] == "Mac"
linux   = false if windows || mac

RUBY_PLATFORM = "mingw" if windows

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

    # Our custom gem list based on 'default' gembox.
    # CLI gems (e.g. mruby, mirb) are bypassed. This can avoid errors when linking them,
    # and they're unnecessary to Windows build.
    conf.gembox "stdlib"
    conf.gembox "stdlib-ext"
    conf.gembox "math"
    conf.gembox "metaprog"

    # Use stdlib-io except mruby-socket (also unnecessary for cross-building)
    conf.gem :core => "mruby-io"
    conf.gem :core => "mruby-print"

    # Generate mrbc command
    conf.gem :core => "mruby-bin-mrbc"

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

  conf.cc.defines = %w(MRUBY_NANOVG_GL2 MRB_ENABLE_DEBUG_HOOK)
  conf.cc.flags << '-O3'
  conf.host_target = 'x86_64-w64-mingw32' if windows

  #No default gems
  # Use standard print/puts/p
  conf.gem :core => "mruby-print"
  conf.gem :core => "mruby-sprintf"

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
  conf.gem 'deps/mruby-errno'
  conf.gem 'mruby/mrbgems/mruby-io'
  conf.gem 'deps/mruby-nanovg'
  conf.gem 'deps/mruby-regexp-pcre'
  conf.gem 'deps/mruby-set'

  if(!windows)
    #Needed for hotloading, but we can ignore that on windows...
    conf.gem 'deps/mruby-file-stat'
    conf.gem 'deps/mruby-dir'
    conf.gem 'deps/mruby-dir-glob'
    #I don't think mruby-process is required for anything besides some tests
    #which we don't run anyway
    conf.gem 'deps/mruby-process'
  end

  demo_mode = false
  if(ENV.include?("BUILD_MODE"))
      if(ENV["BUILD_MODE"] == "demo")
          demo_mode = true
      end
  end

  conf.cc do |cc|
      cc.include_paths << "#{`pwd`.strip}/../deps/nanovg/src"
      cc.include_paths << "#{`pwd`.strip}/../deps/pugl/"
      cc.include_paths << "#{`pwd`.strip}/../deps/libuv/include/" if !linux
      cc.include_paths << "/usr/share/mingw-w64/include/" if windows
      cc.include_paths << "/usr/x86_64-w64-mingw32/include/" if windows
      cc.flags << "-DLDBL_EPSILON=1e-6" if windows
      cc.flags << "-std=gnu99"
      cc.flags << " -fPIC"              if !windows
      cc.flags << "-DWINDOWS_WHY"       if windows
      cc.flags << "-mstackrealign"      if windows
      cc.flags << "-mwindows"           if windows
      cc.flags << "-Wno-declaration-after-statement"
      cc.defines << "UI_HOTLOAD"        if ENV.include?("UI_HOTLOAD")
      cc.defines << "DEMO_MODE=#{demo_mode ? '1':'0'}"
      cc.defines << "MRB_NO_BOXING"
  end

  conf.linker do |linker|
      linker.library_paths  << "#{`pwd`.strip}/../src/osc-bridge/"
      linker.libraries << 'osc-bridge'
      linker.flags_after_libraries  << "#{`pwd`.strip}/../deps/libnanovg.a"
      if(!windows)
        if(!mac)
          linker.libraries << 'GL'
          linker.libraries << 'X11'
          linker.flags_after_libraries << `pkg-config --libs libuv`.strip
        else
          linker.flags_after_libraries  << "#{`pwd`.strip}/../deps/libuv.a"
        end
        linker.flags_after_libraries  << "-lpthread -ldl -lm"
      else
        linker.flags_after_libraries  << "#{`pwd`.strip}/../deps/libuv-win.a"
        linker.flags_after_libraries  << "-lws2_32 -lkernel32 -lpsapi -luserenv -liphlpapi"
        linker.flags_after_libraries  << "-lglu32 -lgdi32 -lopengl32"
      end
  end

  #Custom Gems
  conf.gem 'src/mruby-qml-spawn'
  conf.gem 'src/mruby-qml-parse'
  conf.gem 'src/mruby-zest'

  #Scrap Code Gem
  conf.gem 'src/mruby-widget-lib'

  #conf.gem 'deps/mruby-profiler'
end

MRuby::Build.new('host-debug') do |conf|
  # load specific toolchain settings
  toolchain :gcc

  enable_debug

  if(windows)
    # Our custom gem list based on 'default' gembox.
    # Bypass all CLIs here to avoid linker errors on Msys2.
    conf.gembox "stdlib"
    conf.gembox "stdlib-ext"
    conf.gembox "math"
    conf.gembox "metaprog"

    # Use stdlib-io except mruby-socket (also unnecessary for cross-building debug targets)
    conf.gem :core => "mruby-io"
    conf.gem :core => "mruby-print"

  else
    # include default GEMs
    conf.gembox 'default'
  end

  # C compiler settings
  conf.cc.defines = %w(MRB_ENABLE_DEBUG_HOOK MRUBY_NANOVG_GL2)

  # Generate mruby debugger command (require mruby-eval)
  # Also bypass it when building for/on Windows
  if(!windows)
    conf.gem :core => "mruby-bin-debugger"
  end
end
