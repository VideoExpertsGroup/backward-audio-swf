# backward-audio-swf

The simple Flash audio streamer.

How to install npm

	https://nodejs.org/en/download/package-manager/

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

