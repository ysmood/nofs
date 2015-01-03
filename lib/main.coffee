Promise = require 'bluebird'

fs = require 'fs'
gfs = require 'graceful-fs'

promisify = (fn, self) ->
	(args...) ->
		new Promise (resolve, reject) ->
			args.push ->
				if arguments[0]?
					reject arguments[0]
				else
					resolve arguments[1]
			fn.apply self, args

fsMore = {

	existsP: (path) ->
		new Promise (resolve) ->
			fs.exists path, (exists) ->
				resolve exists

	fileExists: (path, cb) ->
		fs.exists path, (exists) ->
			if exists
				fs.stat path, (err, stats) ->
					cb err, stats.isFile()
			else
				cb null, false

	fileExistsSync: (path) ->
		if fs.existsSync path
			fs.statSync(path).isFile()
		else
			false

	dirExists: (path, cb) ->
		fs.exists path, (exists) ->
			if exists
				fs.stat path, (err, stats) ->
					cb err, stats.isDirectory()
			else
				cb null, false

	dirExistsSync: (path) ->
		if fs.existsSync(path)
			fs.statSync(path).isDirectory()
		else
			false
}

# Overwrite fs with graceful-fs
for k of gfs
	fs[k] = gfs[k]

# Add fs-more functions
for k of fsMore
	fs[k] = fsMore[k]

# Promisify fs.
for k of fs
	if k.slice(-4) == 'Sync'
		name = k[0...-4]
		pname = name + 'P'
		continue if fs[pname]
		fs[pname] = promisify fs[name]


module.exports = fs
