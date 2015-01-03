Promise = require 'bluebird'

fs = require 'fs'
gfs = require 'graceful-fs'

for k of gfs
	fs[k] = gfs[k]

fsx = require 'fs-extra'

promisify = (fn, self) ->
	(args...) ->
		new Promise (resolve, reject) ->
			args.push ->
				if arguments[0]?
					reject arguments[0]
				else
					resolve arguments[1]
			fn.apply self, args

# Denodeify fs.
# Now we can call fs.readFileP with P support.
for k of fsx
	if k.slice(-4) == 'Sync'
		name = k[0...-4]
		fs[name + 'P'] = promisify fsx[name]
		fs[k] = fsx[k]

fs.moveP = promisify fsx.move

fs.existsP = (path) ->
	new Promise (resolve) ->
		fs.exists path, (exists) ->
			resolve exists

fs.fileExists = (path, cb) ->
	fs.exists path, (exists) ->
		if exists
			fs.stat path, (err, stats) ->
				cb err, stats.isFile()
		else
			cb null, false

fs.fileExistsSync = (path) ->
	if fs.existsSync path
		fs.statSync(path).isFile()
	else
		false

fs.fileExistsP = promisify fs.fileExists

fs.dirExists = (path, cb) ->
	fs.exists path, (exists) ->
		if exists
			fs.stat path, (err, stats) ->
				cb err, stats.isDirectory()
		else
			cb null, false

fs.dirExistsSync = (path) ->
	if fs.existsSync(path)
		fs.statSync(path).isDirectory()
	else
		false

fs.dirExistsP = promisify fs.dirExists

module.exports = fs
