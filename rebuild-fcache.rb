require 'set'
require_relative 'src/mruby-qml-parse/mrblib/main.rb'
require_relative 'src/mruby-qml-parse/mrblib/parse-types.rb'
require_relative 'src/mruby-qml-parse/mrblib/parser.rb'
require_relative 'src/mruby-qml-parse/mrblib/prog-ir.rb'
require_relative 'src/mruby-qml-parse/mrblib/prog-vm.rb'
require_relative 'src/mruby-qml-parse/mrblib/react-attr.rb'
require_relative 'src/mruby-qml-spawn/mrblib/build.rb'
require_relative 'src/mruby-qml-spawn/mrblib/database.rb'
require_relative 'src/mruby-qml-spawn/mrblib/loader.rb'

ir = loadIR(nil)
puts "length(IR) = #{ir.length}"
$ruby_mode = :CRuby
QmlIrToRuby.new(ir, nil, "src/mruby-widget-lib/mrblib/fcache.rb")
