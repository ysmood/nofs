###*
 * I hate to reinvent the wheel. But to purely use promise, I don't
 * have many choices.
###
Overview = 'nofs'

Promise = require './bluebird/js/main/bluebird'
npath = require 'path'
fs = require 'fs'
utils = require './utils'

# Evil of Node.
utils.extend fs, require('./graceful-fs/graceful-fs')

# Promisify fs.
for k of fs
	if k.slice(-4) == 'Sync'
		name = k[0...-4]
		pname = name + 'P'
		continue if fs[pname]
		fs[pname] = utils.promisify fs[name]

nofs =

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
	mkdirsP: (path, mode = 0o777 & ~process.umask()) ->
		# Find out how many directory need to be created.
		findList = (path, list = []) ->
			nofs.dirExistsP(path).then (exists) ->
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
	 * @param {Boolean} cache Default is false. If it is true, the return list array
	 * will have an extra property `statCache`, it is something like:
	 * ```coffee
	 * {
	 * 	'path/to/entity': {
	 * 		dev: 16777220
	 * 		mode: 33188
	 * 		...
	 * 	}
	 * }
	 * ```
	 * The key is the entity path, the value is the `fs.Stats` object.
	 * @return {Promise} Resolves an path array. Every directory path will ends
	 * with `/` (Unix) or `\` (Windows).
	###
	readdirsP: (root, filter, cache = false, list) ->
		if not list?
			list = []
			if cache
				statCache = {}
				Object.defineProperty list, 'statCache', {
					value: statCache
					enumerable: false
				}

		fs.readdirP(root).then (paths) ->
			if filter
				paths = paths.filter filter

			Promise.all paths.map (path) ->
				p = npath.join root, path

				fs.statP(p).then (stats) ->
					ret = if stats.isDirectory()
						p = p + npath.sep
						list.push p
						nofs.readdirsP p, filter, cache, list
					else
						list.push p
					list.statCache[p] = stats if cache

					ret
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
				nofs.readdirsSync p, filter, list
			else
				list.push p

		list

	###*
	 * Remove a file or directory peacefully, same with the `rm -rf`.
	 * @param  {String} root
	 * @param {Function} filter Same with the `readdirs`'s.
	 * @return {Promise}
	###
	removeP: (root, filter) ->
		fs.statP(root).then (stats) ->
			if stats.isDirectory()
				nofs.readdirsP(root, filter).then (paths) ->
					# Reverse to Keep a subpath being ordered
					# after its parent.
					Promise.all paths.reverse().map (path) ->
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
	 * > Remark: For `<= Node v0.8` the `opts` can also be an object.
	 * @return {Promise}
	###
	outputFileP: (path, data, opts = {}) ->
		args = arguments
		fs.fileExistsP(path).then (exists) ->
			if exists
				nofs.writeFileP.apply null, args
			else
				dir = npath.dirname path
				fs.mkdirsP(dir, opts.mode).then ->
					nofs.writeFileP.apply null, args

	###*
	 * A `writeFile` shim for `<= Node v0.8`.
	 * @param  {String} path
	 * @param  {String | Buffer} data
	 * @param  {String | Object} opts
	 * @return {Promise}
	###
	writeFileP: (path, data, opts = {}) ->
		switch typeof opts
			when 'string'
				encoding = opts
			when 'object'
				{ encoding, flag, mode } = opts
			else
				throw new TypeError('Bad arguments')

		flag ?= 'w'
		mode ?= 0o777 & ~process.umask()

		fs.openP(path, flag, mode).then (fd) ->
			buf = if data.constructor.name == 'Buffer'
				data
			else
				new Buffer('' + data, encoding)
			pos = if flag.indexOf('a') > -1 then null else 0
			fs.writeP fd, buf, 0, buf.length, pos

# Add nofs functions
utils.extend fs, nofs

for k of fs
	if k.slice(-1) == 'P'
		name = k[0...-1]
		continue if fs[name]
		fs[name] = utils.callbackify fs[k]

module.exports = fs
