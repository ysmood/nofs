nofs = require '../src/main'
npath = require 'path'
{ Promise } = require '../src/utils'

nofs.eachDirP 'test/fixtures/dir', {
	# isReverse: true
	isIncludeRoot: false
}, (s) -> s
.then (ls) ->
	console.log ls
