###*
 * I hate to reinvent the wheel. But to purely use promise, I don't
 * have many choices.
###
Overview = 'nofs'

npath = require 'path'
utils = require './utils'

###*
 * Here I use [Bluebird][Bluebird] only as an ES6 shim for Promise.
 * No APIs other than ES6 spec will be used. In the
 * future it will be removed.
 * [Bluebird]: https://github.com/petkaantonov/bluebird
###
Promise = utils.Promise

# nofs won't pollute the native fs.
fs = utils.extend {}, require 'fs'

# Evil of Node.
utils.extend fs, require('../lib/graceful-fs/graceful-fs')

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
	 * 	# Same with the `readDirs`'s
	 * 	filter: -> true
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
	 * Walk through a path recursively with a callback. The callback
	 * can return a Promise to continue the sequence. The resolving order
	 * is also recursive, a directory path resolves after all its children
	 * are resolved.
	 * @param  {String} path The path may point to a directory or a file.
	 * @param  {Object}   opts Optional. Defaults:
	 * ```coffee
	 * {
	 * 	# The current working directory to search.
	 * 	cwd: ''
	 *
	 * 	# Whehter to follow symbol links or not.
	 * 	isFollowLink: true
	 *
	 * 	# Iterate children first, then parent folder.
	 * 	isReverse: false
	 * }
	 * ```
	 * @param  {Function} fn `(current, isDir, stats) -> Promise | Any`.
	 * The `current` value can be a `String` or an `Object Array`.
	 * If it a string, it's a file path, else it's a directory object.
	 * If the `fn` is `(c) -> c`, the directory object array may look like:
	 * ```coffee
	 * [
	 * 	val: 'dir/path'
	 *
	 * 	'dir/path/a.txt'
	 * 	'dir/path/b.txt'
	 * ]
	 * ```
	 * The `isDir` is a boolean.
	 * The `stats` is a native `fs.Stats` object.
	 * @return {Promise} If the `fn` is `(c) -> c`, it will resolve a direcotry
	 * tree array object, and it may look like:
	 * ```coffee
	 * [
	 * 	val: 'root'
	 *
	 * 	'a.txt'
	 * 	'b.txt'
	 *
	 * 	[
	 * 		val: 'root/path'
	 *
	 * 		'c.txt'
	 * 		'd.txt'
	 * 	]
	 * ]
	 * 	 * ```
	 * @example
	 * ```coffee
	 * # Print all file and directory names, and the modification time.
	 * nofs.eachDirP 'dir/path', (curr, stats) ->
	 * 	console.log curr.dir or curr, stats.mtime
	 *
	 * # Print path name list.
	 * nofs.eachDirP 'dir/path', (curr) -> curr
	 * .then (tree) ->
	 * 	console.log tree
	 * ```
	###
	eachDirP: (path, opts, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		utils.defaults opts, {
			cwd: ''
			isFollowLink: true
			isReverse: false
		}

		stat = if opts.isFollowLink then fs.lstatP else fs.statP

		resolve = (path) -> npath.join opts.cwd, path

		decideNext = (path) ->
			stat(resolve path).then (stats) ->
				isDir = stats.isDirectory()
				if isDir
					if opts.isReverse
						readdir(path).then (arr) ->
							arr.val = path
							fn arr, isDir, stats
					else
						p = fn path, isDir, stats
						p = Promise.resolve(p) if not p or p.then
						p.then (val) ->
							readdir(path).then (arr) ->
								arr.val = val
								arr
				else
					fn path, isDir, stats

		readdir = (dir) ->
			fs.readdirP(resolve dir).then (names) ->
				Promise.all names.map (name) ->
					decideNext npath.join(dir, name)

		decideNext path

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
	 * @param  {String} mode Defaults: `0o777 & ~process.umask()`
	 * @return {Promise}
	###
	mkdirsP: (path, mode = 0o777 & ~process.umask()) ->
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
	 * 	filter: -> true
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
	 * @param {Object} opts Extends the options of `eachDir`. Defaults:
	 * ```coffee
	 * {
	 * 	# To filter paths.
	 * 	filter: (path, stats) -> true
	 *
	 * 	isCacheStats: false
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
	 * nofs.readDirsP 'dir/path'
	 * .then (paths) ->
	 * 	console.log paths # output => ['dir/path/a', 'dir/path/b/c']
	 *
	 * # Same with the above, but cwd is changed.
	 * nofs.readDirsP 'path', { cwd: 'dir' }
	 * .then (paths) ->
	 * 	console.log paths # output => ['path/a', 'path/b/c']
	 *
	 * # CacheStats
	 * nofs.readDirsP 'dir/path', { isCacheStats: true }
	 * .then (paths) ->
	 * 	console.log paths.statsCache['path/a']
	 *
	 * # Find all js files.
	 * nofs.readDirsP 'dir/path', { filter: /.+\.js$/ }
	 * .then (paths) -> console.log paths
	 *
	 * # Custom handler
	 * nofs.readDirsP 'dir/path', {
	 * 	filter: (path, stats) ->
	 * 		path.slice(-1) != '/' and stats.size > 1000
	 * }
	 * .then (paths) -> console.log paths
	 * ```
	###
	readDirsP: (root, opts = {}) ->
		utils.defaults opts, {
			isCacheStats: false
			filter: -> true
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

		nofs.eachDirP root, opts, (path, isDir, stats) ->
			if isDir
				path = path + npath.sep

			if opts.filter path, stats
				list.push path

			if opts.isCacheStats
				statsCache[path] = stats

			return
		.then ->
			list

	###*
	 * Remove a file or directory peacefully, same with the `rm -rf`.
	 * @param  {String} root
	 * @param {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	# Same with the `readDirs`'s.
	 * 	filter: -> true
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
	 * @param  {Object}   opts Extends the options of `eachDir`. But `cwd` is
	 * fixed with the same as the `from` parameter.
	 * @param  {Function} fn `(path, isDir, stats) -> Promise | Any` The callback
	 * will be called with each path. The callback can return a `Promise` to
	 * keep the async sequence go on.
	 * @return {Promise}
	 * @example
	 * ```coffee
	 * # Copy and add license header for each files
	 * # from a folder to another.
	 * nofs.mapDirP(
	 * 	'from'
	 * 	'to'
	 * 	{ isCacheStats: true }
	 * 	(src, dest, isDir) ->
	 * 		return if isDir
	 * 		buf = nofs.readFileP src
	 * 		buf += 'License MIT\n' + buf
	 * 		nofs.writeFileP dest, buf
	 * )
	 * ```
	###
	mapDirP: (from, to, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		opts.cwd = from

		nofs.eachDirP '', opts, (path, isDir, stats) ->
			src = npath.join from, path
			dest = npath.join to, path
			fn src, dest, isDir, stats

	###*
	 * Walk through directory recursively with a callback.
	 * @param  {String}   root
	 * @param  {Object}   opts Extends the options of `eachDir`,
	 * with some extra options:
	 * ```coffee
	 * {
	 * 	# The init value of the walk.
	 * 	init: undefined
	 * }
	 * ```
	 * @param  {Function} fn `(prev, path, isDir, stats) -> Promise`
	 * @return {Promise} Final resolved value.
	 * @example
	 * ```coffee
	 * # Concat all files.
	 * nofs.reduceDirP 'dir/path', { init: '' }, (val, path) ->
	 * 	val += nofs.readFile(path) + '\n'
	 * .then (ret) ->
	 * 	console.log ret
	 * ```
	###
	reduceDirP: (root, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		prev = Promise.resolve(opts.init)

		nofs.eachDirP root, opts, (path, isDir, stats) ->
			prev.then (val) ->
				prev = fn val, path, isDir, stats

	###*
	 * A `writeFile` shim for `< Node v0.10`.
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
