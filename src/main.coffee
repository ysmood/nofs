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
utils.extend fs, require('graceful-fs')

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
	 * See `copyDirP`.
	###
	copyDirSync: (src, dest, opts) ->
		utils.defaults opts, {
			isForce: false
		}

		copy = ->
			if opts.isForce
				try
					fs.rmdirSync dest
				catch err
					if err.code != 'ENOENT'
						throw err

				fs.mkdirSync dest, opts.mode
			else
				fs.mkdirSync dest, opts.mode

		if opts.mode
			copy()
		else
			{ mode } = fs.statSync(src)
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
					copyFile()
			else
				copyFile()

		if opts.mode
			copy()
		else
			fs.statP(src).then ({ mode }) ->
				opts.mode = mode
				copy()

	###*
	 * See `copyDirP`.
	###
	copyFileSync: (src, dest, opts) ->
		utils.defaults opts, {
			isForce: false
		}
		bufLen = 64 * 1024
		buf = new Buffer(bufLen)

		copyFile = ->
			fdr = fs.openSync src, 'r'
			fdw = fs.openSync dest, 'w', opts.mode
			bytesRead = 1
			pos = 0

			while bytesRead > 0
				bytesRead = fs.readSync fdr, buf, 0, bufLen, pos
				fs.writeSync fdw, buf, 0, bytesRead
				pos += bytesRead

			fs.closeSync fdr
			fs.closeSync fdw

		copy = ->
			if opts.isForce
				try
					fs.unlinkSync dest
				catch err
					if err.code != 'ENOENT'
						throw err
				copyFile()
			else
				copyFile()

		if opts.mode
			copy()
		else
			{ mode } = fs.statSync src
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
	 * See `copyP`.
	###
	copySync: (from, to, opts = {}) ->
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
				nofs.copyDirSync src, dest, opts
			else
				nofs.copyFileSync src, dest, opts

		stats = fs.statSync from
		if stats.isDirectory()
			if nofs.dirExistsSync to
				to = npath.join to, npath.basename(from)
			else
				nofs.mkdirsSync npath.dirname(to)

			nofs.mapDirSync from, to, opts, copy
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
	 * 	# To filter paths. It can also be a RegExp or a glob pattern string.
	 * 	filter: -> true
	 *
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
	 * 	val: 'test'
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
	 *
	 * # Find all js files.
	 * nofs.eachDirP 'dir/path', { filter: '**\/*.js' }, ({ path }) ->
	 * 	console.log paths
	 *
	 * # Find all js files.
	 * nofs.eachDirP 'dir/path', { filter: /\.js$/ }, ({ path }) ->
	 * 	console.log paths
	 *
	 * # Custom filter
	 * nofs.eachDirP 'dir/path', {
	 * 	filter: ({ path, stats }) ->
	 * 		path.slice(-1) != '/' and stats.size > 1000
	 * }, (path) ->
	 * 	console.log path
	 * ```
	###
	eachDirP: (path, opts, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		utils.defaults opts, {
			filter: -> true
			cwd: ''
			isIncludeRoot: true
			isFollowLink: true
			isReverse: false
		}

		if opts.filter instanceof RegExp
			reg = opts.filter
			opts.filter = (fileInfo) -> reg.test fileInfo.path

		if typeof opts.filter == 'string'
			pattern = opts.filter
			opts.filter = (fileInfo) ->
				nofs.minimatch fileInfo.path, pattern

		stat = if opts.isFollowLink then fs.lstatP else fs.statP

		resolve = (path) -> npath.join opts.cwd, path

		execFn = (fileInfo) -> fn fileInfo if opts.filter fileInfo

		decideNext = (path) ->
			stat(resolve path).then (stats) ->
				isDir = stats.isDirectory()
				fileInfo = { path, isDir, stats }
				if isDir
					if opts.isReverse
						readdir(path).then (children) ->
							fileInfo.children = children
							execFn fileInfo
					else
						p = execFn fileInfo
						p = Promise.resolve(p) if not p or not p.then
						p.then (val) ->
							readdir(path).then (children) ->
								fileInfo.children = children
								fileInfo.val = val
								fileInfo
				else
					execFn fileInfo

		readdir = (dir) ->
			fs.readdirP(resolve dir).then (names) ->
				Promise.all names.map (name) ->
					decideNext npath.join(dir, name)

		if opts.isIncludeRoot
			decideNext path
		else
			readdir path

	###*
	 * See `eachDirP`.
	 * @return {Object | Array} A tree data structure that
	 * represents the files recursively.
	###
	eachDirSync: (path, opts, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		utils.defaults opts, {
			filter: -> true
			cwd: ''
			isIncludeRoot: true
			isFollowLink: true
			isReverse: false
		}

		if opts.filter instanceof RegExp
			reg = opts.filter
			opts.filter = (fileInfo) -> reg.test fileInfo.path

		if typeof opts.filter == 'string'
			pattern = opts.filter
			opts.filter = (fileInfo) ->
				nofs.minimatch fileInfo.path, pattern

		stat = if opts.isFollowLink then fs.lstatSync else fs.statSync

		resolve = (path) -> npath.join opts.cwd, path

		execFn = (fileInfo) -> fn fileInfo if opts.filter fileInfo

		decideNext = (path) ->
			stats = stat(resolve path)
			isDir = stats.isDirectory()
			fileInfo = { path, isDir, stats }
			if isDir
				if opts.isReverse
					children = readdir(path)
					fileInfo.children = children
					execFn fileInfo
				else
					val = execFn fileInfo
					children = readdir(path)
					fileInfo.children = children
					fileInfo.val = val
					fileInfo
			else
				execFn fileInfo

		readdir = (dir) ->
			names = fs.readdirSync(resolve dir)
			names.map (name) ->
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
	 * The `minimatch` lib.
	 * [Documentation](https://github.com/isaacs/minimatch)
	 * [Offline Documentation](?gotoDoc=minimatch/readme.md)
	 * @type {Funtion}
	###
	minimatch: require 'minimatch'

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
	 * See `mkdirsP`.
	###
	mkdirsSync: (path, mode = 0o777 & ~process.umask()) ->
		makedir = (path) ->
			if not nofs.dirExistsSync path
				parentPath = npath.dirname path
				makedir parentPath
				fs.mkdirSync path, mode
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
	 * See `moveP`.
	###
	moveSync: (from, to, opts = {}) ->
		utils.defaults opts, {
			isForce: false
		}

		opts.isCacheStats = true

		moveFile = (src, dest) ->
			if opts.isForce
				fs.renameSync src, dest
			else
				fs.linkSync(src, dest).then ->
					fs.unlinkSync src

		stats = fs.statSync(from)
		try
			if stats.isDirectory()
				if nofs.dirExistsSync to
					to = npath.join to, npath.basename(from)
				else
					nofs.mkdirsSync npath.dirname(to)
				fs.renameSync from, to
			else
				moveFile from, to
		catch err
			if err.code == 'EXDEV'
				nofs.copySync from, to, opts
				fs.removeSync from
			else
				throw err

	###*
	 * Almost the same as `writeFile`, except that if its parent
	 * directories do not exist, they will be created.
	 * @param  {String} path
	 * @param  {String | Buffer} data
	 * @param  {String | Object} opts Same with the `fs.writeFile`.
	 * @return {Promise}
	###
	outputFileP: (path, data, opts = {}) ->
		fs.fileExistsP(path).then (exists) ->
			if exists
				nofs.writeFileP path, data, opts
			else
				dir = npath.dirname path
				fs.mkdirsP(dir, opts.mode).then ->
					nofs.writeFileP path, data, opts

	###*
	 * See `outputFileP`.
	###
	outputFileSync: (path, data, opts = {}) ->
		if fs.fileExistsSync path
			fs.writeFileSync path, data, opts
		else
			dir = npath.dirname path
			fs.mkdirsSync dir, opts.mode
			fs.writeFileSync path, data, opts

	###*
	 * Read directory recursively.
	 * @param {String} root
	 * @param {Object} opts Extends the options of `eachDir`. Defaults:
	 * ```coffee
	 * {
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
	 * ```
	###
	readDirsP: (root, opts = {}) ->
		utils.defaults opts, {
			isCacheStats: false
			isIncludeRoot: false
		}

		list = []
		statsCache = {}
		Object.defineProperty list, 'statsCache', {
			value: statsCache
			enumerable: false
		}

		nofs.eachDirP root, opts, (fileInfo) ->
			{ path, isDir, stats } = fileInfo

			if opts.isCacheStats
				statsCache[path] = stats

			list.push path
		.then ->
			list

	###*
	 * See `readDirsP`.
	 * @return {Array} Path string array.
	###
	readDirsSync: (root, opts = {}) ->
		utils.defaults opts, {
			isCacheStats: false
			isIncludeRoot: false
		}

		list = []
		statsCache = {}
		Object.defineProperty list, 'statsCache', {
			value: statsCache
			enumerable: false
		}

		nofs.eachDirSync root, opts, (fileInfo) ->
			{ path, isDir, stats } = fileInfo

			if opts.isCacheStats
				statsCache[path] = stats

			list.push path

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
	 * See `removeP`.
	###
	removeSync: (path, opts = {}) ->
		opts.isReverse = true

		try
			stats = fs.statSync(path)
			if stats.isDirectory()
				nofs.eachDirSync path, opts, ({ path, isDir }) ->
					if isDir
						fs.rmdirSync path
					else
						fs.unlinkSync path
			else
				fs.unlinkSync path
		catch err
			if err.code != 'ENOENT' or err.path != path
				throw err

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
	 * @return {Promise} If new file created, resolves true.
	###
	touchP: (path, opts = {}) ->
		now = new Date
		utils.defaults opts, {
			atime: now
			mtime: now
		}

		nofs.fileExistsP(path).then (exists) ->
			(if exists
				fs.utimesP path, opts.atime, opts.mtime
			else
				nofs.outputFileP path, new Buffer(0), opts
			).then ->
				not exists

	###*
	 * See `touchP`.
	 * @return {Boolean} Whether a new file is created or not.
	###
	touchSync: (path, opts = {}) ->
		now = new Date
		utils.defaults opts, {
			atime: now
			mtime: now
		}

		exists = nofs.fileExistsSync path
		if exists
			fs.utimesSync path, opts.atime, opts.mtime
		else
			nofs.outputFileSync path, new Buffer(0), opts

		not exists

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
	 * @return {Promise} Resolves a tree object.
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
	 * See `mapDirP`.
	 * @return {Object | Array} A tree object.
	###
	mapDirSync: (from, to, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		opts.cwd = from

		nofs.eachDirSync '', opts, (fileInfo) ->
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
	 * See `reduceDirP`
	 * @return {Any} Final value.
	###
	reduceDirSync: (path, opts = {}, fn) ->
		if opts instanceof Function
			fn = opts
			opts = {}

		prev = opts.init

		nofs.eachDirSync path, opts, (fileInfo) ->
			prev = fn prev, fileInfo

		prev

	###*
	 * Read A Json file and parse it to a object.
	 * @param  {String} path
	 * @param  {Object | String} opts Same with the native `fs.readFile`.
	 * @return {Promise} Resolves a parsed object.
	 * @example
	 * ```coffee
	 * nofs.readJsonP('a.json').then (obj) ->
	 * 	console.log obj.name, obj.age
	 * ```
	###
	readJsonP: (path, opts = {}) ->
		fs.readFileP(path, opts).then (data) ->
			try
				JSON.parse data + ''
			catch err
				Promise.reject err

	###*
	 * See `readJSONP`.
	 * @return {Any} The parsed object.
	###
	readJsonSync: (path, opts = {}) ->
		data = fs.readFileSync path, opts
		JSON.parse data + ''

	###*
	 * Write a object to a file, if its parent directory doesn't
	 * exists, it will be created.
	 * @param  {String} path
	 * @param  {Any} obj  The data object to save.
	 * @param  {Object | String} opts Extends the options of `outputFileP`.
	 * Defaults:
	 * ```coffee
	 * {
	 * 	replacer: null
	 * 	space: null
	 * }
	 * ```
	 * @return {Promise}
	###
	outputJsonP: (path, obj, opts = {}) ->
		if typeof opts == 'string'
			opts = { encoding: opts }

		try
			str = JSON.stringify obj, opts.replacer, opts.space
		catch err
			return Promise.reject err

		nofs.outputFileP path, str, opts

	###*
	 * See `outputJSONP`.
	###
	outputJsonSync: (path, obj, opts = {}) ->
		if typeof opts == 'string'
			opts = { encoding: opts }

		str = JSON.stringify obj, opts.replacer, opts.space
		nofs.outputFileSync path, str, opts

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

	###*
	 * See `writeFileP`
	###
	writeFileSync: (path, data, opts = {}) ->
		switch typeof opts
			when 'string'
				encoding = opts
			when 'object'
				{ encoding, flag, mode } = opts
			else
				throw new TypeError('Bad arguments')

		flag ?= 'w'
		mode ?= 0o666

		fd = fs.openSync(path, flag, mode)
		buf = if data.constructor.name == 'Buffer'
			data
		else
			new Buffer('' + data, encoding)
		pos = if flag.indexOf('a') > -1 then null else 0
		fs.writeSync fd, buf, 0, buf.length, pos

# Add nofs functions
utils.extend fs, nofs

for k of fs
	if k.slice(-1) == 'P'
		name = k[0...-1]
		continue if fs[name]
		fs[name] = utils.callbackify fs[k]

module.exports = fs
