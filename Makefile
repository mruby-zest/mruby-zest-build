all:
	cd deps/nanovg && premake4 gmake
	cd deps/nanovg/build && make nanovg
	cd mruby && MRUBY_CONFIG=../build_config.rb rake

trace:
	cd mruby && MRUBY_CONFIG=../build_config.rb rake --trace

test:
	cd mruby &&  MRUBY_CONFIG=../build_config.rb rake test

run:
	 ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

scratch:
	 ./mruby/bin/mruby -e "begin;puts doFastLoad;rescue e;puts 'scratch exception';puts e;end ;puts 'scratch done'"

