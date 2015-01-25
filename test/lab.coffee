nofs = require '../src/main'
npath = require 'path'
{ Promise } = require '../src/utils'

nofs.watchPath 'test/basic.coffee', {
	handler: (path) ->
		console.log path
}
