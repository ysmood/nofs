nofs = require '../src/main'
pattern = '../**/*.js'

nofsGlob = ->
	console.time 'nofs-glob'
	nofs.glob pattern, { isFollowLink: false }
	.then (files) ->
		console.timeEnd 'nofs-glob'
		console.log files.length
		files

nofsGlob()
