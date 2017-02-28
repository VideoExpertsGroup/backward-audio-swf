# backward-audio-swf

The simple Flash audio streamer.

How to install npm and grunt in Ubuntu

	Please look here: https://www.digitalocean.com/community/tutorials/node-js-ubuntu-16-04-ru

Installation
============

1. Install Node Packages.

	$ npm install grunt --save-dev
	$ npm install

2. Compile SWF.
Development (places new SWF in /dist/):

	$ grunt mxmlc

Production/ Distribution (runs mxmlc task and copies SWF to dist/):

	$ grunt dist

