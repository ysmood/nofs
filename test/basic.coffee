process.env.pollingWatch = 30

kit = require 'nokit'
nofs = require '../src/main'
{ Promise } = require '../src/utils'
npath = require 'path'

isWin = process.platform == 'win32'
regSep = ///#{'\\' + npath.sep}///g

normalizePath = (val) ->
	if val instanceof Array
		val.map((p) -> p.replace regSep, '/').sort()
	else if typeof val == 'string'
		val.replace regSep, '/'

wait = (time = 500) ->
	new Promise (resolve) ->
		setTimeout ->
			resolve()
		, time

module.exports = (it) -> Promise.all [
	it 'exists', ->
		nofs.exists('readme.md')
		.then (ret) ->
			it.eq ret, true

	it 'dirExists exists', ->
		nofs.dirExists('src').then (ret) ->
			it.eq ret, true

	it 'dirExists non-exists', ->
		nofs.dirExists('asdlkfjf').then (ret) ->
			it.eq ret, false

	it 'dirExistsSync', ->
		it.eq nofs.dirExistsSync('src'), true

	it 'fileExists exists', ->
		nofs.fileExists('readme.md').then (ret) ->
			it.eq ret, true

	it 'fileExists non-exists', ->
		nofs.fileExists('src').then (ret) ->
			it.eq ret, false

	it 'fileExistsSync', ->
		it.eq nofs.fileExistsSync('readme.md'), true

	it 'readFile', -> new Promise (resolve) ->
		nofs.readFile 'test/fixtures/sample.txt', 'utf8', (err, ret) ->
			resolve it.eq ret, 'test'

	it 'readFile', ->
		nofs.readFile 'test/fixtures/sample.txt', 'utf8'
		.then (ret) ->
			it.eq ret, 'test'

	it 'reduceDir', ->
		nofs.reduceDir 'test/fixtures/dir', {
			init: ''
			isReverse: true
			iter: (sum, { path }) ->
				sum += path.slice(-1)
		}
		.then (v) ->
			it.eq v.split('').sort().join(''), 'abcde'

	it 'reduceDirSync', ->
		v = nofs.reduceDirSync 'test/fixtures/dir', {
			init: '', isReverse: true
			iter: (sum, { path }) ->
				sum += path.slice(-1)
		}

		it.eq v.split('').sort().join(''), 'abcde'

	it 'eachDir pattern with filter', ->
		ls = []
		nofs.eachDir 'test/fixtures/dir/**', {
			filter: ({ isDir }) -> isDir
			iter: (fileInfo) -> ls.push fileInfo.name
		}
		.then ->
			it.eq normalizePath(ls), ['test0', 'test1', 'test2']

	it 'eachDirSync pattern with filter', ->
		ls = []
		nofs.eachDirSync 'test/fixtures/dir/**', {
			filter: ({ isDir }) -> isDir
			iter: (fileInfo) -> ls.push fileInfo.name
		}
		it.eq normalizePath(ls), ['test0', 'test1', 'test2']

	it 'eachDir searchFilter', ->
		ls = []
		nofs.eachDir 'test/fixtures/dir', {
			all: false
			searchFilter: ({ path }) ->
				normalizePath(path) != 'test/fixtures/dir/test0'
			iter: (fileInfo) ->
				ls.push fileInfo.name
		}
		.then ->
			it.eq normalizePath(ls), ["a", "d", "dir", "test2"]

	it 'eachDirSync searchFilter', ->
		ls = []
		nofs.eachDirSync 'test/fixtures/dir', {
			searchFilter: ({ path }) ->
				normalizePath(path) != 'test/fixtures/dir/test0'
			iter: (fileInfo) ->
				ls.push fileInfo.name
		}
		it.eq normalizePath(ls), [".e", "a", "d", "dir", "test2"]

	it 'mapDir pattern', ->
		ls = []

		nofs.mapDir(
			'test/fixtures/dir/*0/**'
			'test/fixtures/other'
			iter: (src, dest) ->
				ls.push src + '/' + dest
		).then ->
			it.eq normalizePath(ls), [
				'test/fixtures/dir/test0/b/test/fixtures/other/test0/b'
				'test/fixtures/dir/test0/test1/c/test/fixtures/other/test0/test1/c'
			]

	it 'mapDirSync pattern', ->
		ls = []

		nofs.mapDirSync(
			'test/fixtures/dir/*0/**'
			'test/fixtures/other'
			iter: (src, dest) ->
				ls.push src + '/' + dest
		)
		it.eq normalizePath(ls), [
			'test/fixtures/dir/test0/b/test/fixtures/other/test0/b'
			'test/fixtures/dir/test0/test1/c/test/fixtures/other/test0/test1/c'
		]

	it 'copy', ->
		dir = 'test/fixtures/dir-copy'
		nofs.copy 'test/fixtures/dir', dir
		.then ->
			nofs.glob '**', {
				cwd: dir
			}
		.then (ls) ->
			it.eq normalizePath(ls), [
				"a", "test0", "test0/b", "test0/test1"
				"test0/test1/c", "test2", "test2/d"
			]

	it 'copySync', ->
		dir = 'test/fixtures/dir-copySync'
		nofs.copySync 'test/fixtures/dir', dir
		ls = nofs.globSync '**', {
			cwd: dir
		}
		it.eq normalizePath(ls), [
			"a", "test0", "test0/b", "test0/test1"
			"test0/test1/c", "test2", "test2/d"
		]

	it 'copy self', ->
		dir = 'test/fixtures/dir-copy-self'
		nofs.mkdirsSync dir
		nofs.copy 'test/fixtures/dir/**', dir
		.then ->
			nofs.glob '**', { cwd: dir }
		.then (ls) ->
			it.eq normalizePath(ls), [
				"a", "test0", "test0/b", "test0/test1"
				"test0/test1/c", "test2", "test2/d"
			]

	it 'copySync self', ->
		dir = 'test/fixtures/dir-copySync-self'
		nofs.mkdirsSync dir
		nofs.copySync 'test/fixtures/dir/**', dir

		nofs.glob '**', { cwd: dir }
		.then (ls) ->
			it.eq normalizePath(ls), [
				"a", "test0", "test0/b", "test0/test1"
				"test0/test1/c", "test2", "test2/d"
			]

	it 'copy pattern', ->
		dir = 'test/fixtures/dir-copy-pattern'
		nofs.copy 'test/fixtures/dir/*0/**', dir
		.then ->
			nofs.glob '**', {
				cwd: dir
			}
		.then (ls) ->
			it.eq normalizePath(ls), [
				"test0", "test0/b", "test0/test1"
				"test0/test1/c"
			]

	it 'copySync pattern', ->
		dir = 'test/fixtures/dir-copySync-pattern'
		nofs.copySync 'test/fixtures/dir/*0/**', dir
		ls = nofs.globSync '**', {
			cwd: dir
		}
		it.eq normalizePath(ls), [
			"test0", "test0/b", "test0/test1"
			"test0/test1/c"
		]

	it 'remove', ->
		dir = 'test/fixtures/dir-remove'
		nofs.copySync 'test/fixtures/dir', dir

		nofs.remove dir
		.then ->
			it.eq nofs.dirExistsSync(dir), false

	it 'removeSync', ->
		dir = 'test/fixtures/dir-removeSync'
		nofs.copySync 'test/fixtures/dir', dir

		nofs.removeSync dir
		it.eq nofs.dirExistsSync(dir), false

	it 'remove pattern', ->
		dir = 'test/fixtures/dir-remove-pattern'
		nofs.copySync 'test/fixtures/dir', dir

		nofs.remove 'test/fixtures/dir-remove-pattern/test*'
		.then ->
			it.eq normalizePath(nofs.globSync dir + '/**'),
				['test/fixtures/dir-remove-pattern/a']

	it 'removeSync pattern', ->
		dir = 'test/fixtures/dir-removeSync-pattern'
		nofs.copySync 'test/fixtures/dir', dir

		nofs.removeSync 'test/fixtures/dir-removeSync-pattern/test*'
		it.eq normalizePath(nofs.globSync dir + '/**'),
			['test/fixtures/dir-removeSync-pattern/a']

	it 'remove symbol link', ->
		dir = 'test/fixtures/dir-remove-symbol-link'
		nofs.copySync 'test/fixtures/dir', dir
		nofs.symlinkSync dir + '/test0', dir + '/test0-link', 'dir'

		nofs.remove dir + '/test0-link'
		.then ->
			Promise.all [
				it.eq nofs.dirExistsSync(dir + '/test0-link'), false
				it.eq nofs.dirExistsSync(dir + '/test0'), true
			]

	it 'removeSync symbol link', ->
		dir = 'test/fixtures/dir-removeSync-symbol-link'
		nofs.copySync 'test/fixtures/dir', dir
		nofs.symlinkSync dir + '/test0', dir + '/test0-link', 'dir'

		nofs.removeSync dir + '/test0-link'
		Promise.all [
			it.eq nofs.dirExistsSync(dir + '/test0-link'), false
			it.eq nofs.dirExistsSync(dir + '/test0'), true
		]

	it 'remove race condition', ->
		dir = 'test/fixtures/remove-race'
		nofs.mkdirsSync dir
		nofs.touchSync dir + '/a'
		nofs.touchSync dir + '/b'
		nofs.touchSync dir + '/c'

		Promise.all [
			nofs.remove dir
			nofs.remove dir + '/a'
			nofs.remove dir + '/b'
			nofs.remove dir + '/c'
		]
		.then ->
			it.eq nofs.dirExistsSync(dir), false

	it 'move', ->
		dir = 'test/fixtures/dir-move'
		dir2 = dir + '2'
		nofs.copy 'test/fixtures/dir', dir
		.then ->
			nofs.move dir, dir2
		.then ->
			nofs.glob '**', {
				cwd: dir2
			}
			.then (ls) ->
				it.eq normalizePath(ls), [
					"a", "test0", "test0/b", "test0/test1"
					"test0/test1/c", "test2", "test2/d"
				]

	it 'moveSync', ->
		dir = 'test/fixtures/dir-moveSync'
		dir2 = dir + '2'
		nofs.copySync 'test/fixtures/dir', dir
		nofs.moveSync dir, dir2
		ls = nofs.globSync '**', {
			cwd: dir2
		}
		it.eq normalizePath(ls), [
			"a", "test0", "test0/b", "test0/test1"
			"test0/test1/c", "test2", "test2/d"
		]

	it 'copy move a file', ->

		nofs.copy 'test/fixtures/sample.txt', 'test/fixtures/copySample/sample'
		.then ->
			nofs.move 'test/fixtures/copySample/sample', 'test/fixtures/copySample2/sample'
		.then ->
			nofs.fileExists 'test/fixtures/copySample2/sample'
			.then (exists) ->
				it.eq exists, true

	it 'copySync moveSync a file', ->

		nofs.copy 'test/fixtures/sample.txt', 'test/fixtures/copySampleSync/sample'
		.then ->
			nofs.move 'test/fixtures/copySampleSync/sample', 'test/fixtures/copySampleSync2/sample'
		.then ->
			nofs.fileExists 'test/fixtures/copySampleSync2/sample'
			.then (exists) ->
				it.eq exists, true

	it 'copy filter', ->
		dir = 'test/fixtures/copyFilter'
		nofs.copy 'test/fixtures/dir', dir, { filter: '**/b' }
		.then ->
			nofs.glob dir + '/**'
		.then (ls) ->
			it.eq normalizePath(ls), [
				"test/fixtures/copyFilter/test0","test/fixtures/copyFilter/test0/b"
			]

	it 'copySync filter', ->
		dir = 'test/fixtures/copyFilterSync'
		nofs.copySync 'test/fixtures/dir', dir, { filter: '**/b' }
		ls = nofs.globSync dir + '/**'
		it.eq normalizePath(ls), [
			"test/fixtures/copyFilterSync/test0","test/fixtures/copyFilterSync/test0/b"
		]

	it 'ensureFile', ->
		nofs.ensureFile 'test/fixtures/ensureFile'
		.then ->
			nofs.fileExists 'test/fixtures/ensureFile'
		.then (exists) ->
			it.eq exists, true

	it 'ensureFileSync', ->
		nofs.ensureFileSync 'test/fixtures/ensureFileSync'
		exists = nofs.fileExistsSync 'test/fixtures/ensureFileSync'
		it.eq exists, true

	it 'touch time', ->
		t = Date.now() // 1000
		nofs.touch 'test/fixtures/touch', {
			mtime: t
		}
		.then ->
			nofs.stat 'test/fixtures/touch'
			.then (stats) ->
				it.eq stats.mtime.getTime() // 1000, t

	it 'touchSync time', ->
		t = Date.now() // 1000
		nofs.touchSync 'test/fixtures/touchSync', {
			mtime: t
		}
		stats = nofs.statSync 'test/fixtures/touchSync'
		it.eq stats.mtime.getTime() // 1000, t

	it 'touch create', ->
		nofs.touch 'test/fixtures/touchCreate'
		.then ->
			nofs.fileExists 'test/fixtures/touchCreate'
		.then (exists) ->
			it.eq exists, true

	it 'touchSync create', ->
		nofs.touchSync 'test/fixtures/touchCreate'
		exists = nofs.fileExistsSync 'test/fixtures/touchCreate'
		it.eq exists, true

	it 'outputFile', ->
		nofs.outputFile 'test/fixtures/out/put/file', 'ok'
		.then ->
			nofs.readFile 'test/fixtures/out/put/file', 'utf8'
		.then (str) ->
			it.eq str, 'ok'

	it 'outputFileSync', ->
		nofs.outputFileSync 'test/fixtures/out/put/file', 'ok'
		str = nofs.readFileSync 'test/fixtures/out/put/file', 'utf8'
		it.eq str, 'ok'

	it 'mkdirs', ->
		nofs.mkdirs 'test/fixtures/make/dir/s'
		.then ->
			nofs.dirExists 'test/fixtures/make/dir/s'
		.then (exists) ->
			it.eq exists, true

	it 'mkdirsSync', ->
		nofs.mkdirsSync 'test/fixtures/make/dir/s'
		exists = nofs.dirExistsSync 'test/fixtures/make/dir/s'
		it.eq exists, true

	it 'outputJson readJson', ->
		nofs.outputJson 'test/fixtures/json/json.json', { val: 'test' }
		.then ->
			nofs.readJson 'test/fixtures/json/json.json'
			.then (obj) ->
				it.eq obj, { val: 'test' }

	it 'alias', ->
		nofs.createFile 'test/fixtures/alias/file/path'
		.then ->
			nofs.fileExists 'test/fixtures/alias/file/path'
		.then (exists) ->
			it.eq exists, true

	it 'glob', ->
		nofs.glob '**', {
			cwd: 'test/fixtures/dir'
		}
		.then (ls) ->
			it.eq normalizePath(ls), [
				"a","test0","test0/b","test0/test1","test0/test1/c","test2","test2/d"
			]

	it 'globSync', ->
		ls = nofs.globSync '**', {
			cwd: 'test/fixtures/dir'
		}
		it.eq normalizePath(ls), [
			"a","test0","test0/b","test0/test1","test0/test1/c","test2","test2/d"
		]

	it 'glob non-exists', ->
		nofs.glob 'aaaaaaaaaaaaaa'
		.then (ls) ->
			it.eq normalizePath(ls), []

	it 'globSync non-exists', ->
		ls = nofs.globSync 'aaaaaaaaaaaaaa'
		it.eq normalizePath(ls), []

	it 'glob all', ->
		nofs.glob 'test/fixtures/dir/test2/**', { all: true }
		.then (ls) ->
			it.eq normalizePath(ls), ["test/fixtures/dir/test2/.e","test/fixtures/dir/test2/d"]

	it 'globSync all', ->
		ls = nofs.globSync 'test/fixtures/dir/test2/**', { all: true }
		it.eq normalizePath(ls), ["test/fixtures/dir/test2/.e","test/fixtures/dir/test2/d"]

	it 'glob a file', ->
		nofs.glob './test/fixtures/sample.txt'
		.then (ls) ->
			it.eq normalizePath(ls), ['test/fixtures/sample.txt']

	it 'globSync a file', ->
		ls = nofs.globSync './test/fixtures/sample.txt'
		it.eq normalizePath(ls), ['test/fixtures/sample.txt']

	it 'glob patterns', ->
		nofs.glob [
			'test/fixtures/dir/test2/**'
			'test/fixtures/dir/test0/**'
		]
		.then (ls) ->
			it.eq normalizePath(ls), [
				"test/fixtures/dir/test0/b","test/fixtures/dir/test0/test1",
				"test/fixtures/dir/test0/test1/c","test/fixtures/dir/test2/d"
			]

	it 'globSync patterns', ->
		ls = nofs.globSync [
			'test/fixtures/dir/test2/**'
			'test/fixtures/dir/test0/**'
		]
		it.eq normalizePath(ls), [
			"test/fixtures/dir/test0/b","test/fixtures/dir/test0/test1",
			"test/fixtures/dir/test0/test1/c","test/fixtures/dir/test2/d"
		]

	it 'glob negate patterns', ->
		nofs.glob [
			'test/fixtures/dir/test2/**'
			'test/fixtures/dir/test0/**'
			'!**/c'
		]
		.then (ls) ->
			it.eq normalizePath(ls), [
				"test/fixtures/dir/test0/b","test/fixtures/dir/test0/test1",
				"test/fixtures/dir/test2/d"
			]

	it 'globSync negate patterns', ->
		ls = nofs.globSync [
			'test/fixtures/dir/test2/**'
			'test/fixtures/dir/test0/**'
			'!**/c'
		]
		it.eq normalizePath(ls), [
			"test/fixtures/dir/test0/b","test/fixtures/dir/test0/test1",
			"test/fixtures/dir/test2/d"
		]

	kit.flow([
		-> it 'watchPath', () ->
			path = 'test/fixtures/watchFileTmp.txt'

			new Promise (resolve) ->
				nofs.copySync 'test/fixtures/watchFile.txt', path

				nofs.watchPath path, {
					handler: (p, curr, prev, isDelete) ->
						return if isDelete
						resolve it.eq normalizePath(p), path
				}
				wait().then ->
					nofs.outputFileSync path, 'test'
			.then ->
				nofs.unwatchFile path

		-> it 'watchFiles', () ->
			path = 'test/fixtures/watchFilesTmp.txt'
			pattern = 'test/fixtures/**/*.txt'

			new Promise (resolve) ->
				nofs.copySync 'test/fixtures/watchFile.txt', path
				nofs.watchFiles pattern, {
					handler: (p, curr, prev, isDelete) ->
						return if isDelete
						resolve it.eq normalizePath(p), path
				}
				wait().then ->
					nofs.outputFileSync path, 'test'
			.then ->
				for path in nofs.globSync(pattern)
					nofs.unwatchFile path

		-> it 'watchDir modify', () ->
			tmp = 'test/fixtures/watchDirModify'

			new Promise (resolve) ->
				nofs.copySync 'test/fixtures/watchDir', tmp
				nofs.watchDir tmp, {
					patterns: '*'
					handler: (type, path) ->
						resolve it.eq { type, path: normalizePath(path) }, {
							type: 'modify'
							path: tmp + '/a'
						}
				}
				wait().then ->
					nofs.outputFileSync tmp + '/a', 'ok'
			.then ->
				nofs.unwatchFile tmp
				for path in nofs.globSync(tmp + '/*')
					nofs.unwatchFile path

		-> it 'watchDir create', () ->
			tmp = 'test/fixtures/watchDirCreate'

			new Promise (resolve) ->
				nofs.copySync 'test/fixtures/watchDir', tmp
				nofs.watchDir tmp, {
					patterns: ['/dir0/*']
					handler: (type, path, oldPath, stats) ->
						resolve it.eq {
							type, path: normalizePath(path), isDir: stats.isDirectory()
						}, {
							type: 'create'
							path: tmp + '/dir0/d'
							isDir: false
						}
				}
				wait(1000).then ->
					nofs.outputFileSync tmp + '/dir0/d', 'ok'
			.then ->
				nofs.unwatchFile tmp
				nofs.unwatchFile tmp + '/dir0'
				for path in nofs.globSync(tmp + '/dir0/*')
					nofs.unwatchFile path

		-> it 'watchDir delete', () ->
			tmp = 'test/fixtures/watchDirDelete'

			new Promise (resolve) ->
				nofs.copySync 'test/fixtures/watchDir', tmp
				nofs.watchDir tmp, {
					patterns: ['**', '!a']
					handler: (type, path) ->
						resolve it.eq { type, path: normalizePath(path) }, {
							type: 'delete'
							path: tmp + '/dir0/c'
						}
				}
				wait().then ->
					nofs.removeSync tmp + '/a'
					nofs.removeSync tmp + '/dir0/c'
			.then ->
				nofs.unwatchFile tmp
				for path in nofs.globSync(tmp + '/**')
					nofs.unwatchFile path
	])()
]
