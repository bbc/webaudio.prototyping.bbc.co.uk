# BBC Radiophonics Workshop Web Audio API demo

This repo contains the source code for our project to [recreate the sound of the BBC Radiophonic Workshop using the Web Audio API](http://webaudio.prototyping.bbc.co.uk). You can read more about the project on the BBC R&D blog [here](http://www.bbc.co.uk/rd/blog/2012-05-web-audio-radiophonics-1), [here](http://www.bbc.co.uk/rd/blog/2012-07-web-audio-radiophonics-2), and [here](http://www.bbc.co.uk/blogs/researchanddevelopment/2012/11/audio-on-the-web---explore-the.shtml).

# Install

To build the site yourself, you need to have the following software installed:

* Node.js
* Python
* Ruby

Install the package dependencies:

```bash
npm install
pip install -r requirements.txt
bundle install
```

# Build

Use [CoffeeScript](http://coffeescript.org/) to compile the JavaScript sources:

```bash
make build
```

Generate the annotated source documentation using [docco](https://jashkenas.github.io/docco/) with:

```bash
make doc
```

# Develop

And then build and serve the site using [stasis](https://github.com/winton/stasis):

```bash
make serve
```

The site will be available on [http://localhost:3000](http://localhost:3000).

# Source Code

## Web Audio components

- [Gunfire](src/gunfire.coffee)
- [Ring Modulator](src/ring-modulator.coffee)
- [Tape Loops](src/tapeloops.coffee)
- [Wobbulator](src/wobbulator.coffee)

## Other components

- [Knob](src/knob.coffee)
- [Speech Bubble](src/speechbubble.coffee)
- [Switch](src/switch.coffee)

# License

See COPYING for details.

# Contributing

If you have a feature request or want to report a bug, we'd be happy to hear from you. Please either [raise an issue](https://github.com/bbc/webaudio.prototyping.bbc.co.uk/issues), or fork the project and send us a pull request.

# Authors

This software was written by [Lara Bostock](https://github.com/LaraBostock),
[Chris Lowis](https://github.com/chrislo),
[Chris Needham](https://github.com/chrisn),
[Andrew Nicolaou](https://github.com/andrewn),
[Matthew Paradis](https://github.com/mdjp),
[Thomas Parisot](https://github.com/oncletom), and
[Pete Warren](https://twitter.com/petewarrensnds).

# Copyright

Copyright 2017 British Broadcasting Corporation
