###*
 * I hate to reinvent the wheel. But to purely use promise, I don't
 * have many choices.
###
Overview = 'fs-more'

Promise = require 'bluebird'
npath = require 'path'
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

callbackify = (fn, self) ->
	(args..., cb) ->
		fn.apply self, args
		.then (val) ->
			cb null, val
		.catch cb

# Overwrite fs with graceful-fs
for k of gfs
	fs[k] = gfs[k]

# Promisify fs.
for k of fs
	if k.slice(-4) == 'Sync'
		name = k[0...-4]
		pname = name + 'P'
		continue if fs[pname]
		fs[pname] = promisify fs[name]

fsMore = {

	existsP: (path) ->
		new Promise (resolve) ->
			fs.exists path, (exists) ->
				resolve exists

	fileExistsP: (path) ->
		fs.statP(path).then (stats) ->
			stats.isFile()
		.catch -> false

	fileExistsSync: (path) ->
		if fs.existsSync path
			fs.statSync(path).isFile()
		else
			false

	dirExistsP: (path, cb) ->
		fs.statP(path).then (stats) ->
			stats.isDirectory()
		.catch -> false

	dirExistsSync: (path) ->
		if fs.existsSync(path)
			fs.statSync(path).isDirectory()
		else
			false

	###*
	 * Read directory recursively.
	 * @param  {String} path
	 * @return {Promise} Resolves an path array. Every directory path will ends
	 * with `/` (Unix) or `\` (Windows).
	###
	readdirsP: (root, list = []) ->
		fs.readdirP(root).then (paths) ->
			Promise.all paths.map (path) ->
				p = npath.join root, path

				fs.statP(p).then (stats) ->
					if stats.isDirectory()
						list.push p + npath.sep
						fsMore.readdirsP p, list
					else
						list.push p
		.then -> list

	###*
	 * Read directory recursively.
	 * @param  {String} path
	 * @return {Array} Every directory path will ends
	 * with `/` (Unix) or `\` (Windows).
	###
	readdirsSync: (root, list = []) ->
		paths = fs.readdirSync root

		for path in paths
			p = npath.join root, path
			if fs.statSync(p).isDirectory()
				list.push p + npath.sep
				fsMore.readdirsSync p, list
			else
				list.push p

		list
}

# Add fs-more functions
for k of fsMore
	fs[k] = fsMore[k]

for k of fs
	if k.slice(-1) == 'P'
		name = k[0...-1]
		continue if fs[name]
		fs[name] = callbackify fs[k]

module.exports = fs
