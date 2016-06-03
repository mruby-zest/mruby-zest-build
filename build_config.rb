MRuby::Build.new do |conf|
  # load specific toolchain settings

  toolchain :clang

  enable_debug

  conf.cc.defines = %w(MRUBY_NANOVG_GL2)
  conf.cc.flags << '-O0 -g'

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
      cc.flags << "-std=gnu99"
  end

  conf.linker do |linker|
      linker.library_paths  << "#{`pwd`.strip}/../deps/nanovg/build/"
      linker.library_paths  << "#{`pwd`.strip}/../deps/osc-bridge/"
      linker.libraries << 'GL'
      linker.libraries << 'nanovg'
      linker.libraries << 'X11'
      linker.libraries << 'osc-bridge'
      linker.libraries << 'rtosc'
      linker.libraries << 'uv'
      linker.flags_after_libraries  << "#{`pwd`.strip}/../deps/pugl/build/libpugl-0.a"
  end

  #Custom Gems
  conf.gem 'src/mruby-qml-spawn'
  conf.gem 'src/mruby-qml-parse'
  conf.gem 'src/mruby-zest'
  conf.gem 'src/mruby-layout'

  #Scrap Code Gem
  conf.gem 'src/mruby-widget-lib'

  #Binary Launcher
  conf.gem 'src/mruby-bin-zest'

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
