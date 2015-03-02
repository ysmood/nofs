glob = require 'glob'
pattern = '../**/*.js'

nodeGLob = ->
	console.time 'node-glob'
	glob pattern, { nosort: true, nounique: true }, (err, files) ->
		if err
			console.log err
		else
			console.timeEnd 'node-glob'
			console.log files.length

nodeGLob()
