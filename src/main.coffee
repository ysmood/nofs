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
	 * Copy an empty directory.
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
	 * Copy a single file.
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
	 * @param  {Object} opts Extends the options of `eachDir`.
	 * But the `isCacheStats` is fixed with `true`.
	 * Defaults:
	 * ```coffee
	 * {
	 * 	# Overwrite file if exists.
	 * 	isForce: false
	 * }
	 * ```
	 * @return {Promise}
	###
	copyP: (from, to, opts = {}) ->
		utils.defaults opts, {
			isForce: false
		}

		flags = if opts.isForce then 'w' else 'wx'

		copy = (src, dest, { isDir, stats }) ->
			opts = {
				isForce: opts.isForce
				mode: stats.mode
			}
			if isDir
				nofs.copyDirP src, dest, opts
			else
				nofs.copyFileP src, dest, opts

		fs.statP(from).then (stats) ->
			if stats.isDirectory()
				nofs.dirExistsP(to).then (exists) ->
					if exists
						to = npath.join to, npath.basename(from)
					else
						nofs.mkdirsP npath.dirname(to)
				.then ->
					nofs.mapDirP from, to, opts, copy
			else
				copy from, to, stats

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
	 * 	# Whether to include the root directory or not.
	 * 	isIncludeRoot: true
	 *
	 * 	# Whehter to follow symbol links or not.
	 * 	isFollowLink: true
	 *
	 * 	# Iterate children first, then parent folder.
	 * 	isReverse: false
	 * }
	 * ```
	 * @param  {Function} fn `(fileInfo) -> Promise | Any`.
	 * The `fileInfo` object has these properties: `{ path, isDir, children, stats }`.
	 * If the `fn` is `(c) -> c`, the directory object array may look like:
	 * ```coffee
	 * {
	 * 	path: 'dir/path'
	 * 	isDir: true
	 * 	children: [
	 * 		{ path: 'dir/path/a.txt', isDir: false, stats: { ... } }
	 * 		{ path: 'dir/path/b.txt', isDir: false, stats: { ... } }
	 * 	]
	 * 	stats: {
	 * 		size: 527
	 * 		atime: Mon, 10 Oct 2011 23:24:11 GMT
	 * 		mtime: Mon, 10 Oct 2011 23:24:11 GMT
	 * 		ctime: Mon, 10 Oct 2011 23:24:11 GMT
	 * 		...
	 * 	}
	 * }
	 * ```
	 * The `stats` is a native `fs.Stats` object.
	 * @return {Promise} Resolves a directory tree object.
	 * @example
	 * ```coffee
	 * # Print all file and directory names, and the modification time.
	 * nofs.eachDirP 'dir/path', (obj, stats) ->
	 * 	console.log obj.path, stats.mtime
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
			isIncludeRoot: true
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
						readdir(path).then (children) ->
							fn { path, isDir, children, stats }
					else
						p = fn { path, isDir, stats }
						p = Promise.resolve(p) if not p or not p.then
						p.then (val) ->
							readdir(path).then (children) ->
								{ path, isDir, children }
				else
					fn { path, isDir, stats }

		readdir = (dir) ->
			fs.readdirP(resolve dir).then (names) ->
				Promise.all names.map (name) ->
					decideNext npath.join(dir, name)

		if opts.isIncludeRoot
			decideNext path
		else
			readdir path

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
	 * @param  {Object} opts Extends the options of `eachDir`.
	 * But the `isCacheStats` is fixed with `true`.
	 * Defaults:
	 * ```coffee
	 * {
	 * 	isForce: false
	 * }
	 * ```
	 * @return {Promise} It will resolve a boolean value which indicates
	 * whether this action is taken between two partitions.
	###
	moveP: (from, to, opts = {}) ->
		utils.defaults opts, {
			isForce: false
		}

		opts.isCacheStats = true

		moveFile = (src, dest) ->
			if opts.isForce
				fs.renameP src, dest
			else
				fs.linkP(src, dest).then ->
					fs.unlinkP src

		fs.statP(from).then (stats) ->
			if stats.isDirectory()
				nofs.dirExistsP(to).then (exists) ->
					if exists
						to = npath.join to, npath.basename(from)
					else
						nofs.mkdirsP npath.dirname(to)
				.then ->
					fs.renameP from, to
			else
				moveFile from, to
		.catch (err) ->
			if err.code == 'EXDEV'
				nofs.copyP from, to, opts
				.then ->
					fs.removeP from
			else
				Promise.reject err

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
	 * 	# To filter paths. It can also be a RegExp.
	 * 	filter: -> true
	 *
	 * 	# Don't include the root directory.
	 * 	isIncludeRoot: false
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
	 * nofs.readDirsP 'dir/path', { filter: /\.js$/ }
	 * .then (paths) -> console.log paths
	 *
	 * # Custom handler
	 * nofs.readDirsP 'dir/path', {
	 * 	filter: ({ path, stats }) ->
	 * 		path.slice(-1) != '/' and stats.size > 1000
	 * }
	 * .then (paths) -> console.log paths
	 * ```
	###
	readDirsP: (root, opts = {}) ->
		utils.defaults opts, {
			isCacheStats: false
			isIncludeRoot: false
			filter: -> true
		}

		if opts.filter instanceof RegExp
			reg = opts.filter
			opts.filter = (fileInfo) -> reg.test fileInfo.path

		list = []
		statsCache = {}
		Object.defineProperty list, 'statsCache', {
			value: statsCache
			enumerable: false
		}

		nofs.eachDirP root, opts, (fileInfo) ->
			{ path, isDir, stats } = fileInfo

			if opts.filter fileInfo
				list.push path

			if opts.isCacheStats
				statsCache[path] = stats

			return
		.then ->
			list

	###*
	 * Remove a file or directory peacefully, same with the `rm -rf`.
	 * @param  {String} path
	 * @param {Object} opts Extends the options of `eachDir`. But
	 * the `isReverse` is fixed with `true`.
	 * @return {Promise}
	###
	removeP: (path, opts = {}) ->
		opts.isReverse = true

		fs.statP(path).then (stats) ->
			if stats.isDirectory()
				nofs.eachDirP path, opts, ({ path, isDir }) ->
					if isDir
						fs.rmdirP path
					else
						fs.unlinkP path
			else
				fs.unlinkP path
		.catch (err) ->
			if err.code != 'ENOENT' or err.path != path
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
	 * @param  {Function} fn `(src, dest, fileInfo) -> Promise | Any` The callback
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
	 * 	(src, dest, fileInfo) ->
	 * 		return if fileInfo.isDir
	 * 		nofs.readFileP(src).then (buf) ->
	 * 			buf += 'License MIT\n' + buf
	 * 			nofs.writeFileP dest, buf
	 * )
	 * ```
	###
	mapDirP: (from, to, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		opts.cwd = from

		nofs.eachDirP '', opts, (fileInfo) ->
			src = npath.join from, fileInfo.path
			dest = npath.join to, fileInfo.path
			fn src, dest, fileInfo

	###*
	 * Walk through directory recursively with a callback.
	 * @param  {String}   path
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
	 * nofs.reduceDirP 'dir/path', { init: '' }, (val, info) ->
	 * 	return val if info.isDir
	 * 	nofs.readFileP(info.path).then (str) ->
	 * 		val += str + '\n'
	 * .then (ret) ->
	 * 	console.log ret
	 * ```
	###
	reduceDirP: (path, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		prev = Promise.resolve opts.init

		nofs.eachDirP path, opts, (fileInfo) ->
			prev = prev.then (val) ->
				val = fn val, fileInfo
				if not val or not val.then
					Promise.resolve val
		.then ->
			prev

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
