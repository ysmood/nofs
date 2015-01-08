nofs = require '../src/main'
npath = require 'path'
{ Promise } = require '../src/utils'

nofs.readDirsP 'test/fixtures/dir', {
	isReverse: true
}
.then (ls) ->
	console.log ls
