'use strict'

_ = require './utils'
npath = require './path'
child_process = require 'child_process'

###*
 * Here I use [Yaku](https://github.com/ysmood/yaku) only as an ES6 shim for Promise.
 * No APIs other than ES6 spec will be used. In the
 * future it will be removed.
###
Promise = _.Promise

# nofs won't pollute the native fs.
fs = _.extend {}, (require 'fs')

# Feel pity for Node again.
# The `nofs.exists` api doesn't fulfil the node callback standard.
fs_exists = fs.exists
fs.exists = (path, fn) ->
	fs_exists path, (exists) ->
		fn null, exists

# Promisify fs.
do ->
	for k of fs
		if k.slice(-4) == 'Sync'
			name = k[0...-4]
			fs[name] = _.PromiseUtils.promisify fs[name]

nofs = _.extend {}, {

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
	copyDir: (src, dest, opts) ->
		_.defaults opts, {
			isForce: false
		}

		copy = ->
			(if opts.isForce
				fs.mkdir dest, opts.mode
				.catch (err) ->
					if err.code != 'EEXIST'
						Promise.reject err
			else
				fs.mkdir dest, opts.mode
			).catch (err) ->
				if err.code == 'ENOENT'
					nofs.mkdirs dest
				else
					Promise.reject err

		if opts.mode
			copy()
		else
			fs.stat(src).then ({ mode }) ->
				opts.mode = mode
				copy()

	copyDirSync: (src, dest, opts) ->
		_.defaults opts, {
			isForce: false
		}

		copy = ->
			try
				if opts.isForce
					try
						fs.mkdirSync dest, opts.mode
					catch err
						if err.code != 'EEXIST'
							throw err
				else
					fs.mkdirSync dest, opts.mode
			catch err
				if err.code == 'ENOENT'
					nofs.mkdirsSync dest
				else
					throw err

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
	copyFile: (src, dest, opts) ->
		_.defaults opts, {
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
			(if opts.isForce
				fs.unlink(dest).catch (err) ->
					if err.code != 'ENOENT'
						Promise.reject err
				.then ->
					copyFile()
			else
				copyFile()
			).catch (err) ->
				if err.code == 'ENOENT'
					nofs.mkdirs npath.dirname(dest)
					.then copyFile
				else
					Promise.reject err

		if opts.mode
			copy()
		else
			fs.stat(src).then ({ mode }) ->
				opts.mode = mode
				copy()

	copyFileSync: (src, dest, opts) ->
		_.defaults opts, {
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
			try
				if opts.isForce
					try
						fs.unlinkSync dest
					catch err
						if err.code != 'ENOENT'
							throw err
					copyFile()
				else
					copyFile()
			catch err
				if err.code == 'ENOENT'
					nofs.mkdirsSync npath.dirname(dest)
					copyFile()
				else
					throw err

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
	 * @param  {Object} opts Extends the options of [eachDir](#eachDir-opts).
	 * Defaults:
	 * ```coffee
	 * {
	 * 	# Overwrite file if exists.
	 * 	isForce: false
	 * 	isIterFileOnly: false
	 * }
	 * ```
	 * @return {Promise}
	 * @example
	 * Copy the contents of the directory rather than copy the directory itself.
	 * ```coffee
	 * nofs.copy('dir/path/**', 'dest/path');
	 * ```
	###
	copy: (from, to, opts = {}) ->
		_.defaults opts, {
			isForce: false
			isIterFileOnly: false
		}

		flags = if opts.isForce then 'w' else 'wx'

		opts.iter = (src, dest, { isDir, stats }) ->
			if isDir
				nofs.copyDir src, dest, { isForce: true, mode: opts.mode }
			else
				nofs.copyFile src, dest, { isForce: opts.isForce, mode: opts.mode }

		if pm = nofs.pmatch.isPmatch(from)
			from = nofs.pmatch.getPlainPath pm
			pm = npath.relative from, pm.pattern
			opts.filter = pm

		nofs.dirExists(to).then (exists) ->
			if exists
				if not pm
					to = npath.join to, npath.basename(from)
			else
				nofs.mkdirs npath.dirname(to)
		.then ->
			fs.stat(from)
		.then (stats) ->
			isDir = stats.isDirectory()
			if isDir
				nofs.mapDir from, to, opts
			else
				opts.iter from, to, { isDir, stats }

	copySync: (from, to, opts = {}) ->
		_.defaults opts, {
			isForce: false
			isIterFileOnly: false
		}

		flags = if opts.isForce then 'w' else 'wx'

		opts.iter = (src, dest, { isDir, stats }) ->
			if isDir
				nofs.copyDirSync src, dest, { isForce: true, mode: opts.mode }
			else
				nofs.copyFileSync src, dest, { isForce: opts.isForce, mode: opts.mode }

		if pm = nofs.pmatch.isPmatch(from)
			from = nofs.pmatch.getPlainPath pm
			pm = npath.relative from, pm.pattern
			opts.filter = pm

		if nofs.dirExistsSync to
			if not pm
				to = npath.join to, npath.basename(from)
		else
			nofs.mkdirsSync npath.dirname(to)

		stats = fs.statSync from
		isDir = stats.isDirectory()
		if isDir
			nofs.mapDirSync from, to, opts
		else
			opts.iter from, to, { isDir, stats }

	###*
	 * Check if a path exists, and if it is a directory.
	 * @param  {String}  path
	 * @return {Promise} Resolves a boolean value.
	###
	dirExists: (path) ->
		fs.stat(path).then (stats) ->
			stats.isDirectory()
		.catch -> false

	dirExistsSync: (path) ->
		if fs.existsSync(path)
			fs.statSync(path).isDirectory()
		else
			false

	###*
	 * <a name='eachDir'></a>
	 * Concurrently walks through a path recursively with a callback.
	 * The callback can return a Promise to continue the sequence.
	 * The resolving order is also recursive, a directory path resolves
	 * after all its children are resolved.
	 * @param  {String} spath The path may point to a directory or a file.
	 * @param  {Object} opts Optional. <a id='eachDir-opts'></a> Defaults:
	 * ```coffee
	 * {
	 * 	# Callback on each path iteration.
	 * 	iter: (fileInfo) -> Promise | Any
	 *
	 * 	# Auto check if the spath is a minimatch pattern.
	 * 	isAutoPmatch: true
	 *
	 * 	# Include entries whose names begin with a dot (.), the posix hidden files.
	 * 	all: true
	 *
	 * 	# To filter paths. It can also be a RegExp or a glob pattern string.
	 * 	# When it's a string, it extends the Minimatch's options.
	 * 	filter: (fileInfo) -> true
	 *
	 * 	# The current working directory to search.
	 * 	cwd: ''
	 *
	 * 	# Call iter only when it is a file.
	 * 	isIterFileOnly: false
	 *
	 * 	# Whether to include the root directory or not.
	 * 	isIncludeRoot: true
	 *
	 * 	# Whehter to follow symbol links or not.
	 * 	isFollowLink: true
	 *
	 * 	# Iterate children first, then parent folder.
	 * 	isReverse: false
	 *
	 * 	# When isReverse is false, it will be the previous iter resolve value.
	 * 	val: any
	 *
	 * 	# If it return false, sub-entries won't be searched.
	 * 	# When the `filter` option returns false, its children will
	 * 	# still be itered. But when `searchFilter` returns false, children
	 * 	# won't be itered by the iter.
	 * 	searchFilter: (fileInfo) -> true
	 *
	 * 	# If you want sort the names of each level, you can hack here.
	 * 	# Such as `(names) -> names.sort()`.
	 * 	handleNames: (names) -> names
	 * }
	 * ```
	 * The argument of `opts.iter`, `fileInfo` object has these properties:
	 * ```coffee
	 * {
	 * 	path: String
	 * 	name: String
	 * 	baseDir: String
	 * 	isDir: Boolean
	 * 	children: [fileInfo]
	 * 	stats: fs.Stats
	 * 	val: Any
	 * }
	 * ```
	 * Assume we call the function: `nofs.eachDir('dir', { iter: (f) -> f })`,
	 * the resolved directory object array may look like:
	 * ```coffee
	 * {
	 * 	path: 'some/dir/path'
	 * 	name: 'path'
	 * 	baseDir: 'some/dir'
	 * 	isDir: true
	 * 	val: 'test'
	 * 	children: [
	 * 		{
	 * 			path: 'some/dir/path/a.txt', name: 'a.txt'
	 * 			baseDir: 'dir', isDir: false, stats: { ... }
	 * 		}
	 * 		{ path: 'some/dir/path/b.txt', name: 'b.txt', ... }
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
	 * nofs.eachDir 'dir/path', {
	 * 	iter: (obj, stats) ->
	 * 		console.log obj.path, stats.mtime
	 * }
	 *
	 * # Print path name list.
	 * nofs.eachDir 'dir/path', { iter: (curr) -> curr }
	 * .then (tree) ->
	 * 	console.log tree
	 *
	 * # Find all js files.
	 * nofs.eachDir 'dir/path', {
	 * 	filter: '**\/*.js'
	 * 	iter: ({ path }) ->
	 * 		console.log paths
	 * }
	 *
	 * # Find all js files.
	 * nofs.eachDir 'dir/path', {
	 * 	filter: /\.js$/
	 *  iter: ({ path }) ->
	 * 		console.log paths
	 * }
	 *
	 * # Custom filter.
	 * nofs.eachDir 'dir/path', {
	 * 	filter: ({ path, stats }) ->
	 * 		path.slice(-1) != '/' and stats.size > 1000
	 * 	iter: (path) ->
	 * 		console.log path
	 * }
	 * ```
	###
	eachDir: (spath, opts = {}) ->
		_.defaults opts, {
			isAutoPmatch: true
			all: true
			filter: -> true
			searchFilter: -> true
			handleNames: (names) -> names
			cwd: ''
			isIterFileOnly: false
			isIncludeRoot: true
			isFollowLink: true
			isReverse: false
		}

		stat = if opts.isFollowLink then fs.stat else fs.lstat

		handleSpath = ->
			spath = npath.normalize spath
			if opts.isAutoPmatch and
			pm = nofs.pmatch.isPmatch(spath)
				if nofs.pmatch.isNotPlain pm
					# keep the user defined filter
					opts._filter = opts.filter
					opts.filter = pm
				spath = nofs.pmatch.getPlainPath pm

		handleFilter = ->
			if _.isRegExp opts.filter
				reg = opts.filter
				opts.filter = (fileInfo) -> reg.test fileInfo.path
				return

			pm = null
			if _.isString(opts.filter)
				pm = new nofs.pmatch.Minimatch(opts.filter)
			if opts.filter instanceof nofs.pmatch.Minimatch
				pm = opts.filter
			if pm
				opts.filter = (fileInfo) ->
					# Hot fix for minimatch, it should match '**' to '.'.
					if fileInfo.path == '.'
						return pm.match ''

					pm.match(fileInfo.path) and (
						if _.isFunction opts._filter
							opts._filter fileInfo
						else
							true
					)

				opts.searchFilter = (fileInfo) ->
					# Hot fix for minimatch, it should match '**' to '.'.
					if fileInfo.path == '.'
						return true

					pm.match(fileInfo.path, true)  and (
						if _.isFunction opts._searchFilter
							opts._searchFilter fileInfo
						else
							true
					)

		resolve = (path) -> npath.join opts.cwd, path

		execFn = (fileInfo) ->
			return if not opts.all and fileInfo.name[0] == '.'

			return if opts.isIterFileOnly and fileInfo.isDir

			opts.iter fileInfo if opts.iter? and opts.filter fileInfo

		# TODO: Race Condition
		# It's possible that the file has already gone.
		# Here we silently ignore it, since you normally don't
		# want to iterate a non-exists path.
		raceResolver = (err) ->
			if err.code != 'ENOENT'
				Promise.reject err

		decideNext = (dir, name) ->
			path = npath.join dir, name
			stat(resolve path).catch(raceResolver).then (stats) ->
				return if not stats

				isDir = stats.isDirectory()
				if opts.baseDir == undefined
					opts.baseDir = if isDir then spath else npath.dirname spath
				fileInfo = { path, name, baseDir: opts.baseDir, isDir, stats }

				if isDir
					return if not opts.searchFilter fileInfo

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
			fs.readdir(resolve dir).catch(raceResolver).then (names) ->
				return if not names
				Promise.all opts.handleNames(names).map (name) ->
					decideNext dir, name

		handleSpath()
		handleFilter()

		if opts.isIncludeRoot
			decideNext npath.dirname(spath), npath.basename(spath)
		else
			readdir spath

	eachDirSync: (spath, opts = {}) ->
		_.defaults opts, {
			isAutoPmatch: true
			all: true
			filter: -> true
			searchFilter: -> true
			handleNames: (names) -> names
			cwd: ''
			isIterFileOnly: false
			isIncludeRoot: true
			isFollowLink: true
			isReverse: false
		}

		stat = if opts.isFollowLink then fs.statSync else fs.lstatSync

		handleSpath = ->
			spath = npath.normalize spath
			if opts.isAutoPmatch and
			pm = nofs.pmatch.isPmatch(spath)
				if nofs.pmatch.isNotPlain pm
					# keep the user defined filter
					opts._filter = opts.filter
					opts.filter = pm
				spath = nofs.pmatch.getPlainPath pm

		handleFilter = ->
			if _.isRegExp opts.filter
				reg = opts.filter
				opts.filter = (fileInfo) -> reg.test fileInfo.path
				return

			pm = null
			if _.isString(opts.filter)
				pm = new nofs.pmatch.Minimatch(opts.filter)
			if opts.filter instanceof nofs.pmatch.Minimatch
				pm = opts.filter
			if pm
				opts.filter = (fileInfo) ->
					# Hot fix for minimatch, it should match '**' to '.'.
					if fileInfo.path == '.'
						return pm.match ''

					pm.match(fileInfo.path) and (
						if _.isFunction opts._filter
							opts._filter fileInfo
						else
							true
					)

				opts.searchFilter = (fileInfo) ->
					# Hot fix for minimatch, it should match '**' to '.'.
					if fileInfo.path == '.'
						return true

					pm.match(fileInfo.path, true)  and (
						if _.isFunction opts._searchFilter
							opts._searchFilter fileInfo
						else
							true
					)

		resolve = (path) -> npath.join opts.cwd, path

		execFn = (fileInfo) ->
			return if not opts.all and fileInfo.name[0] == '.'

			return if opts.isIterFileOnly and fileInfo.isDir

			opts.iter fileInfo if opts.iter? and opts.filter fileInfo

		# TODO: Race Condition
		# It's possible that the file has already gone.
		# Here we silently ignore it, since you normally don't
		# want to iterate a non-exists path.
		raceResolver = (err) ->
			if err.code != 'ENOENT'
				throw err

		decideNext = (dir, name) ->
			path = npath.join dir, name

			try
				stats = stat(resolve path)
				isDir = stats.isDirectory()
			catch err
				raceResolver err
				return

			if opts.baseDir == undefined
				opts.baseDir = if isDir then spath else npath.dirname spath
			fileInfo = { path, name, baseDir: opts.baseDir, isDir, stats }

			if isDir
				return if not opts.searchFilter fileInfo

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
			try
				names = fs.readdirSync resolve dir
			catch err
				raceResolver err
				return

			opts.handleNames(names).map (name) ->
				decideNext dir, name

		handleSpath()
		handleFilter()

		if opts.isIncludeRoot
			decideNext npath.dirname(spath), npath.basename(spath)
		else
			readdir spath

	###*
	 * Ensures that the file exists.
	 * Change file access and modification times.
	 * If the file does not exist, it is created.
	 * If the file exists, it is NOT MODIFIED.
	 * @param  {String} path
	 * @param  {Object} opts
	 * @return {Promise}
	###
	ensureFile: (path, opts = {}) ->
		nofs.fileExists(path).then (exists) ->
			if exists
				Promise.resolve()
			else
				nofs.outputFile path, new Buffer(0), opts

	ensureFileSync: (path, opts = {}) ->
		if not nofs.fileExistsSync path
			nofs.outputFileSync path, new Buffer(0), opts

	###*
	 * Check if a path exists, and if it is a file.
	 * @param  {String}  path
	 * @return {Promise} Resolves a boolean value.
	###
	fileExists: (path) ->
		fs.stat(path).then (stats) ->
			stats.isFile()
		.catch -> false

	fileExistsSync: (path) ->
		if fs.existsSync path
			fs.statSync(path).isFile()
		else
			false

	###*
	 * Get files by patterns.
	 * @param  {String | Array} pattern The minimatch pattern.
	 * Patterns that starts with '!' in the array will be used
	 * to exclude paths.
	 * @param {Object} opts Extends the options of [eachDir](#eachDir-opts).
	 * But the `filter` property will be fixed with the pattern.
	 * Defaults:
	 * ```coffee
	 * {
	 * 	all: false
	 *
	 * 	# The minimatch option object.
	 * 	pmatch: {}
	 *
	 * 	# It will be called after each match. It can also return
	 * 	# a promise.
	 * 	iter: (fileInfo, list) -> list.push fileInfo.path
	 * }
	 * ```
	 * @return {Promise} Resolves the list array.
	 * @example
	 * ```coffee
	 * # Get all js files.
	 * nofs.glob(['**\/*.js', '**\/*.css']).then (paths) ->
	 * 	console.log paths
	 *
	 * # Exclude some files. "a.js" will be ignored.
	 * nofs.glob(['**\/*.js', '!**\/a.js']).then (paths) ->
	 * 	console.log paths
	 *
	 * # Custom the iterator. Append '/' to each directory path.
	 * nofs.glob '**\/*.js', {
	 * 	iter: (info, list) ->
	 * 		list.push if info.isDir
	 * 			info.path + '/'
	 * 		else
	 * 			info.path
	 * }
	 * .then (paths) ->
	 * 	console.log paths
	 * ```
	###
	glob: (patterns, opts = {}) ->
		_.defaults opts, {
			pmatch: {}
			all: false
			iter: (fileInfo, list) -> list.push fileInfo.path
		}

		opts.pmatch.dot = opts.all

		if _.isString patterns
			patterns = [patterns]
		patterns = patterns.map npath.normalize

		list = []

		{ pmatches, negateMath } =
			nofs.pmatch.matchMultiple patterns, opts.pmatch

		iter = opts.iter
		opts.iter = (fileInfo) ->
			iter fileInfo, list

		glob = (pm) ->
			newOpts = _.defaults {
				filter: (fileInfo) ->
					return if negateMath fileInfo.path
					if fileInfo.path == '.'
						return pm.match ''
					pm.match fileInfo.path

				searchFilter: (fileInfo) ->
					if fileInfo.path == '.'
						return true
					pm.match fileInfo.path, true
			}, opts

			nofs.eachDir nofs.pmatch.getPlainPath(pm), newOpts

		pmatches.reduce((p, pm) ->
			p.then -> glob(pm)
		, Promise.resolve())
		.then -> list

	globSync: (patterns, opts = {}) ->
		_.defaults opts, {
			pmatch: {}
			all: false
			iter: (fileInfo, list) -> list.push fileInfo.path
		}

		opts.pmatch.dot = opts.all

		if _.isString patterns
			patterns = [patterns]
		patterns = patterns.map npath.normalize

		list = []

		{ pmatches, negateMath } =
			nofs.pmatch.matchMultiple patterns, opts.pmatch

		iter = opts.iter
		opts.iter = (fileInfo) ->
			iter fileInfo, list

		glob = (pm) ->
			newOpts = _.defaults {
				filter: (fileInfo) ->
					return if negateMath fileInfo.path
					if fileInfo.path == '.'
						return pm.match ''
					pm.match fileInfo.path

				searchFilter: (fileInfo) ->
					if fileInfo.path == '.'
						return true
					pm.match fileInfo.path, true
			}, opts

			nofs.eachDirSync nofs.pmatch.getPlainPath(pm), newOpts

		for pm in pmatches
			glob pm
		list

	###*
	 * Map file from a directory to another recursively with a
	 * callback.
	 * @param  {String}   from The root directory to start with.
	 * @param  {String}   to This directory can be a non-exists path.
	 * @param  {Object}   opts Extends the options of [eachDir](#eachDir-opts). But `cwd` is
	 * fixed with the same as the `from` parameter. Defaults:
	 * ```coffee
	 * {
	 * 	# It will be called with each path. The callback can return
	 * 	# a `Promise` to keep the async sequence go on.
	 * 	iter: (src, dest, fileInfo) -> Promise | Any
	 *
	 * 	isIterFileOnly: true
	 * }
	 * ```
	 * @return {Promise} Resolves a tree object.
	 * @example
	 * ```coffee
	 * # Copy and add license header for each files
	 * # from a folder to another.
	 * nofs.mapDir 'from', 'to', {
	 * 	iter: (src, dest) ->
	 * 		nofs.readFile(src).then (buf) ->
	 * 			buf += 'License MIT\n' + buf
	 * 			nofs.outputFile dest, buf
	 * }
	 * ```
	###
	mapDir: (from, to, opts = {}) ->
		_.defaults opts, {
			isIterFileOnly: true
		}

		if pm = nofs.pmatch.isPmatch(from)
			from = nofs.pmatch.getPlainPath pm
			pm = npath.relative from, pm.pattern
			opts.filter = pm

		opts.cwd = from

		iter = opts.iter
		opts.iter = (fileInfo) ->
			src = npath.join from, fileInfo.path
			dest = npath.join to, fileInfo.path
			iter? src, dest, fileInfo

		nofs.eachDir '', opts

	mapDirSync: (from, to, opts = {}) ->
		_.defaults opts, {
			isIterFileOnly: true
		}

		if pm = nofs.pmatch.isPmatch(from)
			from = nofs.pmatch.getPlainPath pm
			pm = npath.relative from, pm.pattern
			opts.filter = pm

		opts.cwd = from

		iter = opts.iter
		opts.iter = (fileInfo) ->
			src = npath.join from, fileInfo.path
			dest = npath.join to, fileInfo.path
			iter? src, dest, fileInfo

		nofs.eachDirSync '', opts

	###*
	 * Recursively create directory path, like `mkdir -p`.
	 * @param  {String} path
	 * @param  {String} mode Defaults: `0o777 & ~process.umask()`
	 * @return {Promise}
	###
	mkdirs: (path, mode = 0o777 & ~process.umask()) ->
		makedir = (path) ->
			# ys TODO:
			# Sometimes I think this async operation is
			# useless, since during the next process tick, the
			# dir may be created.
			# We may use dirExistsSync to avoid this bug, but
			# for the sake of pure async, I leave it still.
			nofs.dirExists(path).then (exists) ->
				if exists
					Promise.resolve()
				else
					parentPath = npath.dirname path
					makedir(parentPath).then ->
						fs.mkdir path, mode
						.catch (err) ->
							if err.code != 'EEXIST'
								Promise.reject err
		makedir path

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
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	isForce: false
	 * 	isFollowLink: false
	 * }
	 * ```
	 * @return {Promise} It will resolve a boolean value which indicates
	 * whether this action is taken between two partitions.
	###
	move: (from, to, opts = {}) ->
		_.defaults opts, {
			isForce: false
			isFollowLink: false
		}

		moveFile = (src, dest) ->
			if opts.isForce
				fs.rename src, dest
			else
				fs.link(src, dest).then ->
					fs.unlink src

		fs.stat(from).then (stats) ->
			nofs.dirExists(to).then (exists) ->
				if exists
					nofs.mkdirs to
					to = npath.join to, npath.basename(from)
				else
					nofs.mkdirs npath.dirname(to)
			.then ->
				if stats.isDirectory()
					fs.rename from, to
				else
					moveFile from, to
		.catch (err) ->
			if err.code == 'EXDEV'
				nofs.copy from, to, opts
				.then ->
					nofs.remove from
			else
				Promise.reject err

	moveSync: (from, to, opts = {}) ->
		_.defaults opts, {
			isForce: false
		}

		moveFile = (src, dest) ->
			if opts.isForce
				fs.renameSync src, dest
			else
				fs.linkSync(src, dest).then ->
					fs.unlinkSync src

		try
			if nofs.dirExistsSync to
				nofs.mkdirsSync to
				to = npath.join to, npath.basename(from)
			else
				nofs.mkdirsSync npath.dirname(to)

			stats = fs.statSync(from)
			if stats.isDirectory()
				fs.renameSync from, to
			else
				moveFile from, to
		catch err
			if err.code == 'EXDEV'
				nofs.copySync from, to, opts
				nofs.removeSync from
			else
				throw err

	###*
	 * Almost the same as `writeFile`, except that if its parent
	 * directories do not exist, they will be created.
	 * @param  {String} path
	 * @param  {String | Buffer} data
	 * @param  {String | Object} opts <a id="outputFile-opts"></a>
	 * Same with the [writeFile](#writeFile-opts).
	 * @return {Promise}
	###
	outputFile: (path, data, opts = {}) ->
		nofs.fileExists(path).then (exists) ->
			if exists
				nofs.writeFile path, data, opts
			else
				dir = npath.dirname path
				nofs.mkdirs(dir, opts.mode).then ->
					nofs.writeFile path, data, opts

	outputFileSync: (path, data, opts = {}) ->
		if nofs.fileExistsSync path
			nofs.writeFileSync path, data, opts
		else
			dir = npath.dirname path
			nofs.mkdirsSync dir, opts.mode
			nofs.writeFileSync path, data, opts

	###*
	 * Write a object to a file, if its parent directory doesn't
	 * exists, it will be created.
	 * @param  {String} path
	 * @param  {Any} obj  The data object to save.
	 * @param  {Object | String} opts Extends the options of [outputFile](#outputFile-opts).
	 * Defaults:
	 * ```coffee
	 * {
	 * 	replacer: null
	 * 	space: null
	 * }
	 * ```
	 * @return {Promise}
	###
	outputJson: (path, obj, opts = {}) ->
		if _.isString opts
			opts = { encoding: opts }

		try
			str = JSON.stringify obj, opts.replacer, opts.space
			str += '\n'
		catch err
			return Promise.reject err

		nofs.outputFile path, str, opts

	outputJsonSync: (path, obj, opts = {}) ->
		if _.isString opts
			opts = { encoding: opts }

		str = JSON.stringify obj, opts.replacer, opts.space
		str += '\n'
		nofs.outputFileSync path, str, opts

	###*
	 * The path module nofs is using.
	 * It's the native [io.js](iojs.org) path lib.
	 * nofs will force all the path separators to `/`,
	 * such as `C:\a\b` will be transformed to `C:/a/b`.
	 * @type {Object}
	###
	path: npath

	###*
	 * The `minimatch` lib. It has two extra methods:
	 * - `isPmatch(String | Object) -> Pmatch | undefined`
	 *     It helps to detect if a string or an object is a minimatch.
	 *
	 * - `getPlainPath(Pmatch) -> String`
	 *     Helps to get the plain root path of a pattern. Such as `src/js/*.js`
	 *     will get `src/js`
	 *
	 * [Documentation](https://github.com/isaacs/minimatch)
	 *
	 * [Offline Documentation](?gotoDoc=minimatch/readme.md)
	 * @example
	 * ```coffee
	 * nofs.pmatch 'a/b/c.js', '**\/*.js'
	 * # output => true
	 * nofs.pmatch.isPmatch 'test*'
	 * # output => true
	 * nofs.pmatch.isPmatch 'test/b'
	 * # output => false
	 * ```
	###
	pmatch: require './pmatch'

	###*
	 * What promise this lib is using.
	 * @type {Promise}
	###
	Promise: Promise

	###*
	 * Same as the [`yaku/lib/utils`](https://github.com/ysmood/yaku#utils).
	 * @type {Object}
	###
	PromiseUtils: _.PromiseUtils

	###*
	 * Read A Json file and parse it to a object.
	 * @param  {String} path
	 * @param  {Object | String} opts Same with the native `nofs.readFile`.
	 * @return {Promise} Resolves a parsed object.
	 * @example
	 * ```coffee
	 * nofs.readJson('a.json').then (obj) ->
	 * 	console.log obj.name, obj.age
	 * ```
	###
	readJson: (path, opts = {}) ->
		fs.readFile(path, opts).then (data) ->
			try
				JSON.parse data + ''
			catch err
				Promise.reject err

	readJsonSync: (path, opts = {}) ->
		data = fs.readFileSync path, opts
		JSON.parse data + ''

	###*
	 * Walk through directory recursively with a iterator.
	 * @param  {String}   path
	 * @param  {Object}   opts Extends the options of [eachDir](#eachDir-opts),
	 * with some extra options:
	 * ```coffee
	 * {
	 * 	iter: (prev, path, isDir, stats) -> Promise | Any
	 *
	 * 	# The init value of the walk.
	 * 	init: undefined
	 *
	 * 	isIterFileOnly: true
	 * }
	 * ```
	 * @return {Promise} Final resolved value.
	 * @example
	 * ```coffee
	 * # Concat all files.
	 * nofs.reduceDir 'dir/path', {
	 * 	init: ''
	 * 	iter: (val, { path }) ->
	 * 		nofs.readFile(path).then (str) ->
	 * 			val += str + '\n'
	 * }
	 * .then (ret) ->
	 * 	console.log ret
	 * ```
	###
	reduceDir: (path, opts = {}) ->
		_.defaults opts, {
			isIterFileOnly: true
		}

		prev = Promise.resolve opts.init

		iter = opts.iter
		opts.iter = (fileInfo) ->
			prev = prev.then (val) ->
				val = iter val, fileInfo
				if not val or not val.then
					Promise.resolve val

		nofs.eachDir(path, opts).then -> prev

	reduceDirSync: (path, opts = {}) ->
		_.defaults opts, {
			isIterFileOnly: true
		}

		prev = opts.init

		iter = opts.iter
		opts.iter = (fileInfo) ->
			prev = iter prev, fileInfo

		nofs.eachDirSync path, opts
		prev

	###*
	 * Remove a file or directory peacefully, same with the `rm -rf`.
	 * @param  {String} path
	 * @param {Object} opts Extends the options of [eachDir](#eachDir-opts). But
	 * the `isReverse` is fixed with `true`. Defaults:
	 * ```coffee
	 * { isFollowLink: false }
	 * ```
	 * @return {Promise}
	###
	remove: (path, opts = {}) ->
		_.defaults opts, { isFollowLink: false }
		opts.isReverse = true
		removeOpts = _.extend {
			iter: ({ path, isDir }) ->
				if isDir
					fs.rmdir path
				else
					fs.unlink path
		}, opts, { isAutoPmatch: false }

		opts.iter = ({ path, isDir }) ->
			if isDir
				fs.rmdir path
				.catch (err) ->
					if err.code == 'ENOTEMPTY'
						return nofs.eachDir path, removeOpts
					Promise.reject err
			else
				fs.unlink path

		nofs.eachDir path, opts

	removeSync: (path, opts = {}) ->
		_.defaults opts, { isFollowLink: false }
		opts.isReverse = true
		removeOpts = _.extend {
			iter: ({ path, isDir }) ->
				if isDir
					fs.rmdirSync path
				else
					fs.unlinkSync path
		}, opts, { isAutoPmatch: false }

		opts.iter = ({ path, isDir }) ->
			if isDir
				try
					fs.rmdirSync path
				catch err
					if err.code == 'ENOTEMPTY'
						return nofs.eachDirSync path, removeOpts
					Promise.reject err
			else
				fs.unlinkSync path

		nofs.eachDirSync path, opts

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
	touch: (path, opts = {}) ->
		now = new Date
		_.defaults opts, {
			atime: now
			mtime: now
		}

		nofs.fileExists(path).then (exists) ->
			(if exists
				fs.utimes path, opts.atime, opts.mtime
			else
				nofs.outputFile path, new Buffer(0), opts
			).then ->
				not exists

	touchSync: (path, opts = {}) ->
		now = new Date
		_.defaults opts, {
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
	 * <a id="writeFile-opts"></a>
	 * Watch a file. If the file changes, the handler will be invoked.
	 * You can change the polling interval by using `process.env.pollingWatch`.
	 * Use `process.env.watchPersistent = 'off'` to disable the persistent.
	 * Why not use `nofs.watch`? Because `nofs.watch` is unstable on some file
	 * systems, such as Samba or OSX.
	 * @param  {String}   path    The file path
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	handler: (path, curr, prev, isDeletion) ->
	 *
	 * 	# Auto unwatch the file while file deletion.
	 * 	autoUnwatch: true
	 *
	 * 	persistent: process.env.watchPersistent != 'off'
	 * 	interval: +process.env.pollingWatch or 300
	 * }
	 * ```
	 * @return {Promise} It resolves the `StatWatcher` object:
	 * ```
	 * {
	 * 	path
	 * 	handler
	 * }
	 * ```
	 * @example
	 * ```coffee
	 * process.env.watchPersistent = 'off'
	 * nofs.watchPath 'a.js', {
	 * 	handler: (path, curr, prev, isDeletion) ->
	 * 		if curr.mtime != prev.mtime
	 * 			console.log path
	 * }
	 * .then (watcher) ->
	 * 	nofs.unwatchFile watcher.path, watcher.handler
	 * ```
	###
	watchPath: (path, opts = {}) ->
		_.defaults opts, {
			autoUnwatch: true
			persistent: process.env.watchPersistent != 'off'
			interval: +process.env.pollingWatch or 300
		}

		handler = (curr, prev) ->
			isDeletion = curr.mtime.getTime() == 0
			opts.handler(path, curr, prev, isDeletion)
			if opts.autoUnwatch and isDeletion
				fs.unwatchFile path, handler

		watcher = fs.watchFile path, opts, handler

		Promise.resolve _.extend(watcher, { path, handler })

	###*
	 * Watch files, when file changes, the handler will be invoked.
	 * It is build on the top of `nofs.watchPath`.
	 * @param  {Array} patterns String array with minimatch syntax.
	 * Such as `['*\/**.css', 'lib\/**\/*.js']`.
	 * @param  {Object} opts Same as the `nofs.watchPath`.
	 * @return {Promise} It contains the wrapped watch listeners.
	 * @example
	 * ```coffee
	 * nofs.watchFiles '*.js', handler: (path, curr, prev, isDeletion) ->
	 * 	console.log path
	 * ```
	###
	watchFiles: (patterns, opts = {}) ->
		nofs.glob(patterns).then (paths) ->
			Promise.all paths.map (path) ->
				nofs.watchPath path, opts

	###*
	 * Watch directory and all the files in it.
	 * It supports three types of change: create, modify, move, delete.
	 * By default, `move` event is disabled.
	 * It is build on the top of `nofs.watchPath`.
	 * @param {String} root
	 * @param  {Object} opts Defaults:
	 * ```coffee
	 * {
	 * 	handler: (type, path, oldPath, stats) ->
	 *
	 * 	patterns: '**' # minimatch, string or array
	 *
	 * 	# Whether to watch POSIX hidden file.
	 * 	all: false
	 *
	 * 	# The minimatch options.
	 * 	pmatch: {}
	 *
	 * 	isEnableMoveEvent: false
	 * }
	 * ```
	 * @return {Promise} Resolves a object that keys are paths,
	 * values are listeners.
	 * @example
	 * ```coffee
	 * # Only current folder, and only watch js and css file.
	 * nofs.watchDir 'lib', {
	 * 	pattern: '*.+(js|css)'
	 * 	handler: (type, path, oldPath, stats) ->
	 * 		console.log type, path, stats.isDirectory()
	 * }
	 * ```
	###
	watchDir: (root, opts = {}) ->
		_.defaults opts, {
			patterns: '**'
			pmatch: {}
			all: false
			error: (err) ->
				console.error err
		}

		opts.pmatch.dot = opts.all

		if _.isString opts.patterns
			opts.patterns = [opts.patterns]
		opts.patterns = opts.patterns.map (p) ->
			if p[0] == '!'
				'!' + npath.join(root, p[1..])
			else
				npath.join root, p

		{ match, negateMath } = nofs.pmatch.matchMultiple(
			opts.patterns
			opts.pmatch
		)

		watchedList = {}

		# TODO: move event
		isSameFile = (statsA, statsB) ->
			# On Unix just "ino" will do the trick, but on Windows
			# "ino" is always zero.
			if statsA.ctime.ino != 0 and statsA.ctime.ino == statsB.ctime.ino
				return true

			# Since "size" for Windows is always zero, and the unit of "time"
			# is second, the code below is not reliable.
			statsA.mtime.getTime() == statsB.mtime.getTime() and
			statsA.ctime.getTime() == statsB.ctime.getTime() and
			statsA.size == statsB.size

		fileHandler = (path, curr, prev, isDelete) ->
			if isDelete
				opts.handler 'delete', path, null, curr
				delete watchedList[path]
			else
				opts.handler 'modify', path, null, curr

		dirHandler = (dir, curr, prev, isDelete) ->
			# Possible Event Order
			# 1. modify event: file modify.
			# 2. delete event: file delete -> parent modify.
			# 3. create event: parent modify -> file create.
			# 4.   move event: file delete -> parent modify -> file create.

			if isDelete
				opts.handler 'delete', dir, null, curr
				delete watchedList[dir]
				return

			# Prevent high frequency concurrent fs changes,
			# we should to use Sync function here. But for
			# now if we don't need `move` event, everything is OK.
			nofs.eachDir dir, { all: opts.all, iter: (fileInfo) ->
				path = fileInfo.path
				if watchedList[path]
					return

				if fileInfo.isDir
					if curr
						opts.handler 'create', path, null, fileInfo.stats
					nofs.watchPath path, { handler: dirHandler }
					.then (listener) ->
						watchedList[path] = listener if listener
				else if not negateMath(path) and match(path)
					if curr
						opts.handler 'create', path, null, fileInfo.stats
					nofs.watchPath path, { handler: fileHandler }
					.then (listener) ->
						watchedList[path] = listener if listener
			}

		dirHandler(root).then -> watchedList

	###*
	 * A `writeFile` shim for `< Node v0.10`.
	 * @param  {String} path
	 * @param  {String | Buffer} data
	 * @param  {String | Object} opts
	 * @return {Promise}
	###
	writeFile: (path, data, opts = {}) ->
		switch typeof opts
			when 'string'
				encoding = opts
			when 'object'
				{ encoding, flag, mode } = opts
			else
				return Promise.reject new TypeError('Bad arguments')

		flag ?= 'w'
		mode ?= 0o666

		fs.open(path, flag, mode).then (fd) ->
			buf = if data.constructor.name == 'Buffer'
				data
			else
				new Buffer('' + data, encoding)
			pos = if flag.indexOf('a') > -1 then null else 0
			fs.write fd, buf, 0, buf.length, pos
			.then ->
				fs.close fd

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
		fs.closeSync fd

}

do ->
	for k of nofs
		if k.slice(-4) == 'Sync'
			name = k[0...-4]
			fs[name] = _.PromiseUtils.callbackify nofs[name]
		fs[k] = nofs[k]

require('./alias')(fs)

module.exports = fs
