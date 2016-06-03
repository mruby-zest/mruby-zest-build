all:
	cd deps/nanovg       && premake4 gmake
	cd deps/nanovg/build && make nanovg
	cd deps/pugl         && ./waf configure --no-cairo --static
	cd deps/pugl         && ./waf
	cd deps/osc-bridge   && make
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake

push:
	cd deps/osc-bridge      && git push
	cd src/mruby-layout     && git push
	cd src/mruby-qml-parse  && git push
	cd src/mruby-qml-spawn  && git push
	cd src/mruby-zest       && git push
	git push

status:
	cd deps/osc-bridge      && git status
	cd src/mruby-layout     && git status
	cd src/mruby-qml-parse  && git status
	cd src/mruby-qml-spawn  && git status
	cd src/mruby-zest       && git status
	git status


verbose: ## Compile mruby with --trace
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake --trace

trace:
	cd mruby && MRUBY_CONFIG=../build_config.rb rake --trace

test:
	cd mruby &&  MRUBY_CONFIG=../build_config.rb rake test

rtest:
	cd src/mruby-qml-parse && ruby test-non-mruby.rb
	cd src/mruby-qml-spawn && ruby test-non-mruby.rb

run: ## Run the toolkit
	 ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

valgrind: ## Launch with valgrind
	 valgrind ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

callgrind: ## Launch with callgrind
	 valgrind --tool=callgrind --dump-instr=yes --collect-jumps=yes ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

gdb:
	 gdb --args ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

gltrace: ## Launch with apitrace
	/work/mytmp/apitrace/build/apitrace trace ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun{doFastLoad}"

qtrace:
	/work/mytmp/apitrace/build/qapitrace ./mruby.trace

scratch:
	 ./mruby/bin/mruby scratch.rb

clean: ## Clean Build Data
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake clean

pack:
	rm -rf package
	mkdir package
	mkdir package/schema
	mkdir package/qml
	mkdir package/font
	cp src/mruby-zest/qml/* package/qml/
	cp src/mruby-zest/example/* package/qml/
	cp deps/osc-bridge/schema/test.json package/schema/
	cp mruby/bin/mruby package/
	cp mruby/bin/zest package/
	cp deps/nanovg/example/*.ttf package/font/
	cp /usr/bin/glpsol package/
	cp /usr/lib/libglpk.so.36.1.2 package/
	cd package && ln -sf libglpk.so.36.1.2 libglpk.so.36
	#cp /usr/lib64/libglpk.so.36.0.1 package/
	echo `date` > package/VERSION
	echo '#!/bin/sh' > package/run.sh
	echo 'LD_LIBRARY_PATH="." ./zest' >> package/run.sh
	chmod +x package/run.sh
	rm -f zest-dist.tar
	rm -f zest-dist.tar.bz2
	tar cf zest-dist.tar package/
	bzip2 zest-dist.tar

pack32: ## Create 64bit Linux Package
	make pack
	mv zest-dist.tar.bz2 zest-dist-x86.tar.bz2

pack64: ## Create 64bit Linux Package
	make pack
	mv zest-dist.tar.bz2 zest-dist-x86_64.tar.bz2

.PHONY: help

help: ## This help
		@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


