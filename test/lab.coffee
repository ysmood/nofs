nofs = require '../src/main'
npath = require 'path'
{ Promise } = require '../src/utils'

nofs.copyP 'test/fixtures/sample.txt', 'test/fixtures/sample2'
.then (ls) ->
	console.log ls
