
UV_DIR    = libuv-v1.9.1
GLPK_DIR  = glpk-4.52
GLPK_FILE = $(GLPK_DIR).tar.gz
UV_FILE   = $(UV_DIR).tar.gz
GLPK_URL  = https://ftp.gnu.org/gnu/glpk/$(GLPK_FILE)
UV_URL    = http://dist.libuv.org/dist/v1.9.1/$(UV_FILE)

all:
	cd deps/nanovg/src   && $(CC) nanovg.c -c
	$(AR) rc deps/libnanovg.a deps/nanovg/src/*.o
	cd deps/pugl         && ./waf configure --no-cairo --static
	cd deps/pugl         && ./waf
	cd src/osc-bridge    && make lib
	cd mruby             && MRUBY_CONFIG=../build_config.rb rake
	
windows:
	cd deps/nanovg/src   && $(CC) nanovg.c -c
	$(AR) rc deps/libnanovg.a deps/nanovg/src/*.o
	cd deps/pugl         && ./waf configure --no-cairo --static --target=win32
	cd deps/pugl         && ./waf
	cd src/osc-bridge    && make lib
	cd mruby             && WINDOWS=1 MRUBY_CONFIG=../build_config.rb rake

builddep:
	cd deps/$(UV_DIR)    && ./autogen.sh
	cd deps/$(UV_DIR)    && ./configure
	cd deps/$(UV_DIR)    && make
	cp deps/$(UV_DIR)/.libs/libuv.a deps/
	cd deps/$(GLPK_DIR)  && ./configure
	cd deps/$(GLPK_DIR)  && make
	cd deps/$(GLPK_DIR)  && $(CC) examples/glpsol.c -I src/ src/.libs/libglpk.a -o glpsol -lm
	cp deps/$(GLPK_DIR)/glpsol deps/
	cd deps/rtosc        && $(CC) -std=c99 src/*.c -I include -c
	cd deps/rtosc        && $(AR) rcs librtosc.a ./*.o
	cp deps/rtosc/librtosc.a deps/

builddepwin:
	cd deps/$(UV_DIR)   && ./autogen.sh
	cd deps/$(UV_DIR)   && ./configure  --host=x86_64-w64-mingw32
	cd deps/$(UV_DIR)   && LD=x86_64-w64-mingw32-gcc make
	cp deps/$(UV_DIR)/.libs/libuv.a deps/
	#cd deps/$(GLPK_DIR) && CFLAGS="-DDBL_EPSILON=2e-16" ./configure --disable-shared --enable-static --host=x86_64-w64-mingw32
	#cd deps/$(GLPK_DIR) && LD=x86_64-w64-mingw32-gcc make
	#cd deps/$(GLPK_DIR) && x86_64-w64-mingw32-gcc examples/glpsol.c -I src/ src/.libs/libglpk.a -o glpsol.exe -lm
	#cp deps/$(GLPK_DIR)/glpsol.exe deps/
	cp deps/glpk-4.52/w64/glpk_4_52.dll deps/
	cp deps/glpk-4.52/w64/glpsol.exe deps/
	cd deps/rtosc       && x86_64-w64-mingw32-gcc src/*.c -I include -c
	cd deps/rtosc       && x86_64-w64-mingw32-ar rcs librtosc.a ./*.o
	cp deps/rtosc/librtosc.a deps/

setup:
	cd deps              && wget $(GLPK_URL)
	cd deps              && tar xvf $(GLPK_FILE)
	cd deps              && wget $(UV_URL)
	cd deps              && tar xvf $(UV_FILE)

setupwin:
	cd deps              && wget http://downloads.sourceforge.net/winglpk/winglpk/GLPK-4.52/winglpk-4.52.zip
	cd deps              && unzip winglpk*
	cd deps              && wget $(UV_URL)
	cd deps              && tar xvf $(UV_FILE)

push:
	cd src/osc-bridge      && git push
	cd src/mruby-layout     && git push
	cd src/mruby-qml-parse  && git push
	cd src/mruby-qml-spawn  && git push
	cd src/mruby-zest       && git push
	git push

status:
	cd src/osc-bridge      && git status
	cd src/mruby-layout     && git status
	cd src/mruby-qml-parse  && git status
	cd src/mruby-qml-spawn  && git status
	cd src/mruby-zest       && git status
	git status

diff:
	cd src/osc-bridge      && git diff
	cd src/mruby-layout     && git diff
	cd src/mruby-qml-parse  && git diff
	cd src/mruby-qml-spawn  && git diff
	cd src/mruby-zest       && git diff
	git diff

stats:
	@echo 'main repo        commits: ' `git log --oneline | wc -l`
	@echo 'mruby-zest       commits: ' `cd src/mruby-zest      && git log --oneline | wc -l`
	@echo 'mruby-layout     commits: ' `cd src/mruby-layout    && git log --oneline | wc -l`
	@echo 'mruby-qml-parse  commits: ' `cd src/mruby-qml-parse && git log --oneline | wc -l`
	@echo 'mruby-qml-spawn  commits: ' `cd src/mruby-qml-spawn && git log --oneline | wc -l`
	@echo 'osc-bridge       commits: ' `cd src/osc-bridge      && git log --oneline | wc -l`
	@echo 'number of qml    files:' `find . -type f | grep -e qml$$ | wc -l`
	@echo 'number of ruby   files:' `find src/ -type f | grep -e rb$$ | wc -l`
	@echo 'number of c      files:' `find src/ -type f | grep -e c$$ | wc -l`
	@echo 'number of header files:' `find src/ -type f | grep -e h$$ | wc -l`
	@echo 'lines of OSC schema:' `wc -l src/osc-bridge/schema/test.json`
	@echo 'lines of qml:'
	@wc -l `find src/ -type f | grep qml$$` | tail -n 1
	@echo 'lines of ruby:'
	@wc -l `find src/ -type f | grep -e rb$$` | tail -n 1
	@echo 'lines of c source:'
	@wc -l `find src/ -type f | grep -e c$$` | tail -n 1
	@echo 'lines of c header:'
	@wc -l `find src/ -type f | grep -e h$$` | tail -n 1
	@echo 'total lines of code:'
	@wc -l `find src/ -type f | grep -Ee "(qml|rb|c|h)$$"` | tail -n 1


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
	 ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun lambda{doFastLoad}"

valgrind: ## Launch with valgrind
	 valgrind --leak-check=full ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun lambda{doFastLoad}"

callgrind: ## Launch with callgrind
	 valgrind --tool=callgrind --dump-instr=yes --collect-jumps=yes ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun lambda{doFastLoad}"

gdb:
	 gdb --args ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun lambda{doFastLoad}"

gltrace: ## Launch with apitrace
	/work/mytmp/apitrace/build/apitrace trace ./mruby/bin/mruby -e "zr=ZRunner.new;zr.doRun lambda{doFastLoad}"

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
	cp src/osc-bridge/schema/test.json package/schema/
	cp mruby/bin/mruby package/
	cp mruby/bin/zest package/
	cp deps/nanovg/example/*.ttf package/font/
	cp deps/glpsol package/
	echo `date` > package/VERSION
	echo '#!/bin/sh' > package/run.sh
	echo './zest --no-hotload' >> package/run.sh
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

put32: ## Push to the server
	scp zest-dist-x86.tar.bz2 mark@fundamental-code.com:/var/www/htdocs/zest/

put64: ## Push to the server
	scp zest-dist-x86_64.tar.bz2 mark@fundamental-code.com:/var/www/htdocs/zest/

packsrc:
	git-archive-all zynaddsubfx-3.0.0.tar.bz2

putsrc:
	scp zynaddsubfx-3.0.0.tar.bz2 mark@fundamental-code.com:/var/www/htdocs/zest/


.PHONY: help

help: ## This help
		@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


