###*
 * I hate to reinvent the wheel. But to purely use promise, I don't
 * have many choices.
###
Overview = 'nofs'

npath = require 'path'
utils = require './utils'

###*
 * Here I use Bluebird only as an ES6 shim for Promise.
 * No APIs other than ES6 spec will be used.
###
Promise = utils.Promise

# nofs won't pollute the native fs.
fs = utils.extend {}, require 'fs'

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
	 * Copy a directory.
	 * @param  {String} src
	 * @param  {String} dest
	 * @param  {Object} opts
	 * ```coffee
	 * {
	 * 	isForce: false
	 * 	mode: auto
	 * }
	 * ```
	 * @return {Promise}
	###
	copyDirP: (src, dest, opts) ->
		utils.defaults opts, {
			isForce: false
		}

		copy = ->
			if opts.isForce
				fs.rmdirP(dest).catch (err) ->
					if err.code != 'ENOENT'
						Promise.reject err
				.then ->
					fs.mkdirP dest, opts.mode
			else
				fs.mkdirP dest, opts.mode

		if opts.mode
			copy()
		else
			fs.statP(src).then ({ mode }) ->
				opts.mode = mode
				copy()

	###*
	 * Copy a file.
	 * @param  {String} src
	 * @param  {String} dest
	 * @param  {Object} opts
	 * ```coffee
	 * {
	 * 	isForce: false
	 * 	mode: auto
	 * }
	 * ```
	 * @return {Promise}
	###
	copyFileP: (src, dest, opts) ->
		utils.defaults opts, {
			isForce: false
		}

		copyFile = ->
			new Promise (resolve, reject) ->
				try
					sDest = fs.createWriteStream dest, opts
					sSrc = fs.createReadStream src
				catch err
					reject err
				sSrc.on 'error', reject
				sDest.on 'error', reject
				sDest.on 'close', resolve
				sSrc.pipe sDest

		copy = ->
			if opts.isForce
				fs.unlinkP(dest).catch (err) ->
					if err.code != 'ENOENT'
						Promise.reject err
				.then ->
					copyFile src, dest, opts.mode
			else
				copyFile src, dest, opts.mode


		if opts.mode
			copy()
		else
			fs.statP(src).then ({ mode }) ->
				opts.mode = mode
				copy()

	###*
	 * Like `cp -r`.
	 * @param  {String} from Source path.
	 * @param  {String} to Destination path.
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	# Overwrite file if exists.
	 * 	isForce: false
	 *
	 * 	# Same with the `readdirs`'s
	 * 	filter: (path) -> true
	 * }
	 * ```
	 * @return {Promise}
	###
	copyP: (from, to, opts = {}) ->
		utils.defaults opts, {
			isForce: false
		}

		flags = if opts.isForce then 'w' else 'wx'

		walkOpts = {
			filter: opts.filter
			isCacheStats: true
		}

		copy = (src, dest, stats) ->
			opts = {
				isForce: opts.isForce
				mode: stats.mode
			}
			if stats.isFile()
				nofs.copyFileP src, dest, opts
			else
				nofs.copyDirP src, dest, opts

		fs.statP(from).then (stats) ->
			if stats.isFile()
				copy from, to, stats
			else
				nofs.dirExistsP(to).then (exists) ->
					if exists
						to = npath.join to, npath.basename(from)
					nofs.mkdirsP to, stats.mode
				.then ->
					nofs.mapDirP from, to, walkOpts, copy

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

	###*
	 * Walk through directory recursively with a callback.
	 * @param  {String}   root
	 * @param  {Object}   opts It extend the options of `readdirs`,
	 * with some extra options:
	 * ```coffee
	 * {
	 * 	# Walk children files first.
	 * 	isReverse: false
	 * }
	 * ```
	 * @param  {Function} fn `(path, stats) -> Promise`
	 * @return {Promise} Final resolved value.
	 * @example
	 * ```coffee
	 * # Print path name list.
	 * nofs.eachDirP 'dir/path', (path) ->
	 * 	console.log path
	 *
	 * # Print path name list.
	 * nofs.eachDirP 'dir/path', { isCacheStats: true }, (path, stats) ->
	 * 	console.log path, stats.isFile()
	 * ```
	###
	eachDirP: (root, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		nofs.reduceDirP root, opts, (nil, path, stats) ->
			fn path, stats

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
	 * Recursively create directory path, like `mkdir -p`.
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
	 * Behaves like the Unix `mv`.
	 * @param  {String} from Source path.
	 * @param  {String} to   Destination path.
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	isForce: false
	 * 	filter: (path) -> true
	 * }
	 * ```
	 * @return {Promise} It will resolve a boolean value which indicates
	 * whether this action is taken between two partitions.
	###
	moveP: (from, to, opts = {}) ->
		utils.defaults opts, {
			isForce: false
		}

		walkOpts = {
			filter: opts.filter
			isCacheStats: true
		}

		moveFile = (src, dest) ->
			if opts.isForce
				fs.renameP src, dest
			else
				fs.linkP(src, dest).then ->
					fs.unlinkP src

		moveDir = (src, dest, { mode }) ->
			nofs.copyDirP src, dest, {
				isForce: opts.isForce
				mode
			}

		move = (src, dest, stats) ->
			isFile = stats.isFile()
			action = if isFile then moveFile else moveDir

			action src, dest, stats
			.catch (err) ->
				if err.code == 'EXDEV'
					action = if isFile
						nofs.copyFileP
					else
						nofs.copyDirP
					action src, dest, {
						isForce: opts.isForce
						mode: stats.mode
					}
				else
					Promise.reject err

		fs.statP(from).then (stats) ->
			if stats.isFile()
				moveFile from, to
			else
				nofs.dirExistsP(to).then (exists) ->
					if exists
						to = npath.join to, npath.basename(from)
					nofs.mkdirsP to
				.then ->
					nofs.mapDirP from, to, walkOpts, move
				.then ->
					fs.removeP from

	###*
	 * Almost the same as `writeFile`, except that if its parent
	 * directories do not exist, they will be created.
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
	 * @param {String} root
	 * @param {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	# To filter paths.
	 * 	filter: (path) -> true
	 *
	 * 	isCacheStats: false
	 *
	 * 	# The current working directory to search.
	 * 	cwd: ''
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
	 * @example
	 * ```coffee
	 * # Basic
	 * nofs.readdirsP 'dir/path'
	 * .then (paths) ->
	 * 	console.log paths # output => ['dir/path/a', 'dir/path/b/c']
	 *
	 * # Same with the above, but cwd is changed.
	 * nofs.readdirsP 'path', { cwd: 'dir' }
	 * .then (paths) ->
	 * 	console.log paths # output => ['path/a', 'path/b/c']
	 *
	 * # CacheStats
	 * nofs.readdirsP 'dir/path', { isCacheStats: true }
	 * .then (paths) ->
	 * 	console.log paths.statsCache['path/a']
	 *
	 * # Find all js files.
	 * nofs.readdirsP 'dir/path', { filter: /.+\.js$/ }
	 * .then (paths) -> console.log paths
	 *
	 * # Custom handler
	 * nofs.readdirsP 'dir/path', {
	 * 	filter: (path) ->
	 * 		path.indexOf('a') > -1
	 * }
	 * .then (paths) -> console.log paths
	 * ```
	###
	readdirsP: (root, opts = {}) ->
		utils.defaults opts, {
			isCacheStats: false
			cwd: ''
		}

		if opts.filter instanceof RegExp
			reg = opts.filter
			opts.filter = (path) -> reg.test path

		list = []
		statsCache = {}
		Object.defineProperty list, 'statsCache', {
			value: statsCache
			enumerable: false
		}

		resolve = (path) -> npath.join opts.cwd, path

		nextDir = (nextPath) ->
			fs.statP(resolve nextPath).then (stats) ->
				ret = if stats.isDirectory()
					nextPath = nextPath + npath.sep
					list.push nextPath
					readdir nextPath
				else
					list.push nextPath

				if opts.isCacheStats
					list.statsCache[nextPath] = stats
				ret

		readdir = (root) ->
			fs.readdirP(resolve root).then (paths) ->
				Promise.all(for path in paths
					nextPath = npath.join root, path

					if opts.filter and not opts.filter(nextPath)
						continue

					nextDir nextPath
				)

		readdir(root).then -> list

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
		opts.isReverse = true

		fs.statP(root).then (stats) ->
			if stats.isFile()
				fs.unlinkP root
			else
				nofs.eachDirP root, opts, (path) ->
					if path.slice(-1) == npath.sep
						fs.rmdirP path
					else
						fs.unlinkP path
				.then ->
					fs.rmdirP root
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
	 * Map file from a directory to another recursively with a
	 * callback.
	 * @param  {String}   from The root directory to start with.
	 * @param  {String}   to This directory can be a non-exists path.
	 * @param  {Object}   opts Same with the `readdirs`. But `cwd` is
	 * fixed with the same as the `from` parameter.
	 * @param  {Function} fn The callback will be called
	 * with each path. The callback can return a `Promise` to
	 * keep the async sequence go on.
	 * @return {Promise}
	 * @example
	 * ```coffee
	 * nofs.mapDirP(
	 * 	'from'
	 * 	'to'
	 * 	{ isCacheStats: true }
	 * 	(src, dest, stats) ->
	 * 		return if stats.isDirectory()
	 * 		buf = nofs.readFileP src
	 * 		buf += 'some contents'
	 * 		nofs.writeFileP dest, buf
	 * )
	 * ```
	###
	mapDirP: (from, to, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		opts.cwd = from

		nofs.eachDirP '', opts, (path, stats) ->
			src = npath.join from, path
			dest = npath.join to, path
			fn src, dest, stats

	###*
	 * Walk through directory recursively with a callback.
	 * @param  {String}   root
	 * @param  {Object}   opts It extend the options of `readdirs`,
	 * with some extra options:
	 * ```coffee
	 * {
	 * 	# Walk children files first.
	 * 	isReverse: false
	 *
	 * 	# The init value of the walk.
	 * 	init: undefined
	 * }
	 * ```
	 * @param  {Function} fn `(preVal, path, stats) -> Promise`
	 * @return {Promise} Final resolved value.
	 * @example
	 * ```coffee
	 * # Print path name list.
	 * nofs.reduceDirP 'dir/path', { init: '' }, (val, path) ->
	 * 	val += path + '\n'
	 * .then (ret) ->
	 * 	console.log ret
	 * ```
	###
	reduceDirP: (root, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		utils.defaults opts, {
			isReverse: false
		}

		nofs.readdirsP root, opts
		.then (paths) ->
			paths.reverse() if opts.isReverse
			paths.reduce (promise, path) ->
				if promise.then
					promise.then (val) ->
						fn val, path, paths.statsCache[path]
				else
					Promise.resolve(
						fn val, path, paths.statsCache[path]
					)
			, Promise.resolve(opts.init)

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
