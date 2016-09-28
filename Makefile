SHELL := /bin/bash
PATH := ./node_modules/.bin:$(PATH)

build: coffee doc html

coffee:
	coffee --compile --bare -o ./js ./src

doc:
	docco src/*.coffee

html:
	rbenv exec bundle exec stasis -p ./public

serve:
	rbenv exec bundle exec stasis -d 3000

clean:
	@-rm -f js/*.js
	@-rm -rf docs
	@-rm -rf public

.PHONY: build coffee doc html serve clean
