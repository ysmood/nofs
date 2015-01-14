nofs = require '../src/main'
npath = require 'path'
{ Promise } = require '../src/utils'

nofs.watchDir {
	dir: 'test/fixtures/watchDir'
	handler: (type, path) ->
		console.log type, path
}
