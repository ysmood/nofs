
glob = require 'glob'
nofs = require '../src/main'

pattern = 'node_modules/**/*.js'

console.time('node-glob')
glob pattern, (err, files) ->
	if err
		console.log err
	else
		console.timeEnd('node-glob')

	console.time 'nofs-glob'
	nofs.glob pattern
	.then (list) ->
		console.timeEnd 'nofs-glob'
