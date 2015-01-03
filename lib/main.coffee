###*
 * I hate to reinvent the wheel. But to purely use promise, I don't
 * have many choices.
###
Overview = 'fs-more'

Promise = require './bluebird/js/main/bluebird'
npath = require 'path'
fs = require 'fs'

# Evil of Node.
gfs = require './graceful-fs/graceful-fs'

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

	###*
	 * Check if a path exists, and if it is a directory.
	 * @param  {String}  path
	 * @return {Promise} Resolves a boolean value.
	###
	dirExistsP: (path) ->
		fs.statP(path).then (stats) ->
			stats.isDirectory()
		.catch -> false

	###*
	 * Check if a path exists, and if it is a directory.
	 * @param  {String}  path
	 * @return {boolean}
	###
	dirExistsSync: (path) ->
		if fs.existsSync(path)
			fs.statSync(path).isDirectory()
		else
			false

	# Feel pity for Node again.
	# The `fs.exists` api doesn't fulfil the node callback standard.
	existsP: (path) ->
		new Promise (resolve) ->
			fs.exists path, (exists) ->
				resolve exists

	###*
	 * Check if a path exists, and if it is a file.
	 * @param  {String}  path
	 * @return {Promise} Resolves a boolean value.
	###
	fileExistsP: (path) ->
		fs.statP(path).then (stats) ->
			stats.isFile()
		.catch -> false

	###*
	 * Check if a path exists, and if it is a file.
	 * @param  {String}  path
	 * @return {boolean}
	###
	fileExistsSync: (path) ->
		if fs.existsSync path
			fs.statSync(path).isFile()
		else
			false

	###*
	 * Recursively mkdir, like `mkdir -p`.
	 * @param  {String} path
	 * @param  {String} mode Defauls: `0o777 & (~process.umask())`
	 * @return {Promise}
	###
	mkdirsP: (path, mode = 0o777 & (~process.umask())) ->
		# Find out how many directory need to be created.
		findList = (path, list = []) ->
			fsMore.dirExistsP(path).then (exists) ->
				if exists
					Promise.resolve list
				else
					list.push path
					findList npath.dirname(path), list

		findList(path).then (list) ->
			list.reverse().reduce (p, path) ->
				p.then -> fs.mkdirP path, mode
			, Promise.resolve()

	###*
	 * Read directory recursively.
	 * @param {String} path
	 * @param {Function} filter To filter paths. Defaults:
	 * ```coffee
	 * (path) -> true
	 * ```
	 * @return {Promise} Resolves an path array. Every directory path will ends
	 * with `/` (Unix) or `\` (Windows).
	###
	readdirsP: (root, filter, list = []) ->
		fs.readdirP(root).then (paths) ->
			if filter
				paths = paths.filter filter

			Promise.all paths.map (path) ->
				p = npath.join root, path

				fs.statP(p).then (stats) ->
					if stats.isDirectory()
						list.push p + npath.sep
						fsMore.readdirsP p, filter, list
					else
						list.push p
		.then -> list

	###*
	 * Read directory recursively.
	 * @param  {String} path
	 * @param {Function} filter To filter paths. Defaults:
	 * ```coffee
	 * (path) -> true
	 * ```
	 * @return {Array} Every directory path will ends
	 * with `/` (Unix) or `\` (Windows).
	###
	readdirsSync: (root, filter, list = []) ->
		paths = fs.readdirSync root
		if filter
			paths = paths.filter filter

		for path in paths
			p = npath.join root, path
			if fs.statSync(p).isDirectory()
				list.push p + npath.sep
				fsMore.readdirsSync p, filter, list
			else
				list.push p

		list

	###*
	 * Remove a file or directory peacefully, same with the `rm -rf`.
	 * @param  {String} root
	 * @return {Promise}
	###
	removeP: (root) ->
		fs.statP(root).then (stats) ->
			if stats.isDirectory()
				fsMore.readdirsP(root).then (paths) ->
					# This is a fast algorithm to keep a subpath
					# being ordered after its parent.
					paths.sort (a, b) ->
						if a.indexOf(b) == 0 then -1 else 1

					Promise.all paths.map (path) ->
						if path.slice(-1) == npath.sep
							fs.rmdirP path
						else
							fs.unlinkP path
				.then ->
					fs.rmdirP root
			else
				fs.unlinkP root
		.catch (err) ->
			if err.code != 'ENOENT' or err.path != root
				Promise.reject err

	###*
	 * Almost the same as `writeFile`, except that if its parent
	 * directory does not exist, it will be created.
	 * @param  {String} path
	 * @param  {String | Buffer} data
	 * @param  {String | Object} opts Same with the `fs.writeFile`.
	 * > Remark: For Node v0.8 the `opts` can only be a string.
	 * @return {Promise}
	###
	outputFileP: (path, data, opts) ->
		args = arguments
		fs.fileExistsP(path).then (exists) ->
			if exists
				fs.writeFileP.apply null, args
			else
				dir = npath.dirname path
				fs.mkdirsP(dir, opts.mode).then ->
					fs.writeFileP.apply null, args
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
