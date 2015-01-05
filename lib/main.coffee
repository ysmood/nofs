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
	 * Like `cp -r`.
	 * @param  {String} from Source path.
	 * @param  {String} to Destination path.
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	# Overwrite file if exists.
	 * 	force: false
	 *
	 * 	# Same with the `readdirs`'s
	 * 	filter: (path) -> true
	 *
	 * 	isDelete: false
	 * }
	 * ```
	 * @return {Promise}
	###
	copyP: (from, to, opts = {}) ->
		utils.defaults opts, {
			force: false
			filter: undefined
			isDelete: false
		}

		flags = if opts.force then 'w' else 'wx'

		nofs.dirExistsP to
		.then (exists) ->
			if exists
				to = npath.join to, npath.basename(from)
				nofs.mkdirsP to
			else
				nofs.mkdirsP to
		.then ->
			nofs.readdirsP from, {
				filter: opts.filter
				isCacheStats: true
				cwd: from
			}
		.then (paths) ->
			Promise.all paths.map (path) ->
				dest = npath.join to, path
				src = npath.join from, path
				mode = paths.statsCache[path].mode
				isDir = src.slice(-1) == npath.sep
				promise = if isDir
					fs.mkdirP dest, mode
				else
					copy = ->
						new Promise (resolve, reject) ->
							try
								sSrc = fs.createReadStream src
								sDest = fs.createWriteStream dest, { mode }
							catch err
								reject err
							sSrc.on 'error', reject
							sDest.on 'error', reject
							sDest.on 'close', resolve
							sSrc.pipe sDest

					if opts.force
						fs.unlinkP(dest).catch(->).then copy
					else
						copy()

				if opts.isDelete
					promise.then ->
						if isDir
							fs.rmdirP src
						else
							fs.unlinkP src
				else
					promise

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
	 * @param  {String} mode Defauls: `0o777`
	 * @return {Promise}
	###
	mkdirsP: (path, mode = 0o777) ->
		makedir = (path) ->
			nofs.dirExistsP(path).then (exists) ->
				if exists
					Promise.resolve()
				else
					parentPath = npath.dirname path
					makedir(parentPath).then ->
						fs.mkdirP path, mode
		makedir path

	###*
	 * Moves a file or directory. Also works between partitions.
	 * @param  {String} from Source path.
	 * @param  {String} to   Destination path.
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	force: true
	 * }
	 * ```
	 * @return {Promise}
	###
	moveP: (from, to, opts) ->

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
	 * Read directory recursively.
	 * @param {String} path
	 * @param {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	# To filter paths.
	 * 	filter: (path) -> true
	 * 	isCacheStats: false
	 * 	cwd: '.'
	 * }
	 * ```
	 * If `isCacheStats` is set true, the return list array
	 * will have an extra property `statsCache`, it is something like:
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
	readdirsP: (root, opts = {}) ->
		utils.defaults opts, {
			filter: undefined
			isCacheStats: false
			cwd: '.'
		}

		list = []
		if opts.isCacheStats
			statsCache = {}
			Object.defineProperty list, 'statsCache', {
				value: statsCache
				enumerable: false
			}

		readdirs = (root) ->
			cwd = npath.relative opts.cwd, root
			fs.readdirP(root).then (paths) ->
				if opts.filter
					paths = paths.filter opts.filter

				Promise.all paths.map (path) ->
					nextPath = npath.join root, path

					fs.statP(nextPath).then (stats) ->
						currPath = npath.join cwd, path
						ret = if stats.isDirectory()
							currPath = currPath + npath.sep
							list.push currPath
							readdirs nextPath
						else
							list.push currPath

						if opts.isCacheStats
							list.statsCache[currPath] = stats
						ret

		readdirs(root).then -> list

	###*
	 * Remove a file or directory peacefully, same with the `rm -rf`.
	 * @param  {String} root
	 * @param {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	# Same with the `readdirs`'s.
	 * 	filter: (path) -> true
	 * }
	 * ```
	 * @return {Promise}
	###
	removeP: (root, opts = {}) ->
		fs.statP(root).then (stats) ->
			if stats.isDirectory()
				nofs.readdirsP(root, opts).then (paths) ->
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
	 * Change file access and modification times.
	 * If the file does not exist, it is created.
	 * @param  {String} path
	 * @param  {Object} opts Default:
	 * ```coffee
	 * {
	 * 	atime: Date.now()
	 * 	mtime: Date.now()
	 * 	mode: undefined
	 * }
	 * ```
	 * @return {Promise}
	###
	touchP: (path, opts = {}) ->
		now = new Date
		utils.defaults opts, {
			atime: now
			mtime: now
		}

		nofs.fileExistsP(path).then (exists) ->
			if exists
				fs.utimesP path, opts.atime, opts.mtime
			else
				nofs.outputFileP path, new Buffer(0), opts

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
		mode ?= 0o666

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
