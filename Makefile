all:
	cd deps/nanovg       && premake4 gmake
	cd deps/nanovg/build && make nanovg
	cd deps/pugl         && ./waf configure --no-cairo --static
	cd deps/pugl         && ./waf
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake

verbose:
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake --trace

trace:
	cd mruby && MRUBY_CONFIG=../build_config.rb rake --trace

test:
	cd mruby &&  MRUBY_CONFIG=../build_config.rb rake test

run:
	 ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

valgrind:
	 valgrind ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

gdb:
	 gdb --args ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

gltrace:
	/work/mytmp/apitrace/build/apitrace trace ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

qtrace:
	/work/mytmp/apitrace/build/qapitrace ./mruby.trace

scratch:
	 ./mruby/bin/mruby -e "begin;puts doFastLoad;rescue e;puts 'scratch exception';puts e;end ;puts 'scratch done'"

clean:
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake clean
