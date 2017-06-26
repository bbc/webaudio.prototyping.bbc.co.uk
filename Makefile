SHELL := /bin/bash
PATH := ./node_modules/.bin:$(PATH)

build: coffee doc html

coffee:
	coffee --compile --bare -o ./js ./src

doc:
	docco src/*.coffee

html:
	bundle exec stasis -p ./public

serve: build
	bundle exec stasis -d 3000

dist: build
	tar cvzf webaudio.tar.gz public

clean:
	@-rm -f js/*.js
	@-rm -rf docs
	@-rm -rf public
	@-rm -f webaudio.tar.gz

.PHONY: build coffee doc html serve dist clean
