process.env.pollingWatch = 30

nofs = require '../src/main'
{ Promise } = require '../src/utils'
npath = require 'path'

assert = require 'assert'

isWin = process.platform == 'win32'
regSep = ///#{'\\' + npath.sep}///g

shouldEqual = (args...) ->
	try
		assert.strictEqual.apply assert, args
	catch err
		Promise.reject err

shouldEqualDone = (done, args...) ->
	try
		assert.strictEqual.apply assert, args
		done()
	catch err
		done err

shouldDeepEqual = (args...) ->
	try
		assert.deepEqual.apply assert, args
	catch err
		Promise.reject err

shouldDeepEqualDone = (done, args...) ->
	try
		assert.deepEqual.apply assert, args
		done()
	catch err
		done err

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

describe 'Basic:', ->
	it 'exists', ->
		nofs.exists('readme.md')
		.then (ret) ->
			shouldEqual ret, true

	it 'dirExists exists', ->
		nofs.dirExists('src').then (ret) ->
			shouldEqual ret, true

	it 'dirExists non-exists', ->
		nofs.dirExists('asdlkfjf').then (ret) ->
			shouldEqual ret, false

	it 'dirExistsSync', ->
		assert.equal nofs.dirExistsSync('src'), true

	it 'fileExists exists', ->
		nofs.fileExists('readme.md').then (ret) ->
			shouldEqual ret, true

	it 'fileExists non-exists', ->
		nofs.fileExists('src').then (ret) ->
			shouldEqual ret, false

	it 'fileExistsSync', ->
		assert.equal nofs.fileExistsSync('readme.md'), true

	it 'readFile', (tdone) ->
		nofs.readFile 'test/fixtures/sample.txt', 'utf8', (err, ret) ->
			try
				assert.equal ret, 'test'
				tdone()
			catch err
				tdone err

	it 'readFile', ->
		nofs.readFile 'test/fixtures/sample.txt', 'utf8'
		.then (ret) ->
			shouldEqual ret, 'test'

	it 'reduceDir', ->
		nofs.reduceDir 'test/fixtures/dir', {
			init: ''
			isReverse: true
			iter: (sum, { path }) ->
				sum += path.slice(-1)
		}
		.then (v) ->
			shouldEqual v.split('').sort().join(''), 'abcde'

	it 'reduceDirSync', ->
		v = nofs.reduceDirSync 'test/fixtures/dir', {
			init: '', isReverse: true
			iter: (sum, { path }) ->
				sum += path.slice(-1)
		}

		shouldEqual v.split('').sort().join(''), 'abcde'

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
			shouldDeepEqual normalizePath(ls), ["a", "d", "dir", "test2"]

	it 'eachDirSync searchFilter', ->
		ls = []
		nofs.eachDirSync 'test/fixtures/dir', {
			searchFilter: ({ path }) ->
				normalizePath(path) != 'test/fixtures/dir/test0'
			iter: (fileInfo) ->
				ls.push fileInfo.name
		}
		shouldDeepEqual normalizePath(ls), [".e", "a", "d", "dir", "test2"]

	it 'mapDir pattern', ->
		ls = []

		nofs.mapDir(
			'test/fixtures/dir/*0/**'
			'test/fixtures/other'
			iter: (src, dest) ->
				ls.push src + '/' + dest
		).then ->
			shouldDeepEqual ls.sort(), [
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
		shouldDeepEqual ls.sort(), [
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
			shouldDeepEqual normalizePath(ls), [
				".", "a", "test0", "test0/b", "test0/test1"
				"test0/test1/c", "test2", "test2/d"
			]

	it 'copySync', ->
		dir = 'test/fixtures/dir-copySync'
		nofs.copySync 'test/fixtures/dir', dir
		ls = nofs.globSync '**', {
			cwd: dir
		}
		shouldDeepEqual normalizePath(ls), [
			".", "a", "test0", "test0/b", "test0/test1"
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
			shouldDeepEqual normalizePath(ls), [
				".", "test0", "test0/b", "test0/test1"
				"test0/test1/c"
			]

	it 'copySync pattern', ->
		dir = 'test/fixtures/dir-copySync-pattern'
		nofs.copySync 'test/fixtures/dir/*0/**', dir
		ls = nofs.globSync '**', {
			cwd: dir
		}
		shouldDeepEqual normalizePath(ls), [
			".", "test0", "test0/b", "test0/test1"
			"test0/test1/c"
		]

	it 'remove', ->
		dir = 'test/fixtures/dir-remove'
		nofs.copySync 'test/fixtures/dir', dir

		nofs.remove dir
		.then ->
			shouldEqual nofs.dirExistsSync(dir), false

	it 'removeSync', ->
		dir = 'test/fixtures/dir-removeSync'
		nofs.copySync 'test/fixtures/dir', dir

		nofs.removeSync dir
		shouldEqual nofs.dirExistsSync(dir), false

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
				shouldDeepEqual normalizePath(ls), [
					".", "a", "test0", "test0/b", "test0/test1"
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
		shouldDeepEqual normalizePath(ls), [
			".", "a", "test0", "test0/b", "test0/test1"
			"test0/test1/c", "test2", "test2/d"
		]

	it 'copy move a file', ->

		nofs.copy 'test/fixtures/sample.txt', 'test/fixtures/copySample/sample'
		.then ->
			nofs.move 'test/fixtures/copySample/sample', 'test/fixtures/copySample2/sample'
		.then ->
			nofs.fileExists 'test/fixtures/copySample2/sample'
			.then (exists) ->
				shouldEqual exists, true

	it 'copySync moveSync a file', ->

		nofs.copy 'test/fixtures/sample.txt', 'test/fixtures/copySampleSync/sample'
		.then ->
			nofs.move 'test/fixtures/copySampleSync/sample', 'test/fixtures/copySampleSync2/sample'
		.then ->
			nofs.fileExists 'test/fixtures/copySampleSync2/sample'
			.then (exists) ->
				shouldEqual exists, true

	it 'copy filter', ->
		dir = 'test/fixtures/copyFilter'
		nofs.copy 'test/fixtures/dir', dir, { filter: '**/b' }
		.then ->
			nofs.glob dir + '/**'
		.then (ls) ->
			shouldDeepEqual normalizePath(ls), [
				"test/fixtures/copyFilter/test0","test/fixtures/copyFilter/test0/b"
			]

	it 'copySync filter', ->
		dir = 'test/fixtures/copyFilter'
		nofs.copySync 'test/fixtures/dir', dir, { filter: '**/b' }
		ls = nofs.globSync dir + '/**'
		shouldDeepEqual normalizePath(ls), [
			"test/fixtures/copyFilter/test0","test/fixtures/copyFilter/test0/b"
		]

	it 'touch time', ->
		t = Date.now() // 1000
		nofs.touch 'test/fixtures/touch', {
			mtime: t
		}
		.then ->
			nofs.stat 'test/fixtures/touch'
			.then (stats) ->
				shouldEqual stats.mtime.getTime() // 1000, t

	it 'touchSync time', ->
		t = Date.now() // 1000
		nofs.touchSync 'test/fixtures/touchSync', {
			mtime: t
		}
		stats = nofs.statSync 'test/fixtures/touchSync'
		shouldEqual stats.mtime.getTime() // 1000, t

	it 'touch create', ->
		nofs.touch 'test/fixtures/touchCreate'
		.then ->
			nofs.fileExists 'test/fixtures/touchCreate'
		.then (exists) ->
			shouldEqual exists, true

	it 'touchSync create', ->
		nofs.touchSync 'test/fixtures/touchCreate'
		exists = nofs.fileExistsSync 'test/fixtures/touchCreate'
		shouldEqual exists, true

	it 'outputFile', ->
		nofs.outputFile 'test/fixtures/out/put/file', 'ok'
		.then ->
			nofs.readFile 'test/fixtures/out/put/file', 'utf8'
		.then (str) ->
			shouldEqual str, 'ok'

	it 'outputFileSync', ->
		nofs.outputFileSync 'test/fixtures/out/put/file', 'ok'
		str = nofs.readFileSync 'test/fixtures/out/put/file', 'utf8'
		shouldEqual str, 'ok'

	it 'mkdirs', ->
		nofs.mkdirs 'test/fixtures/make/dir/s'
		.then ->
			nofs.dirExists 'test/fixtures/make/dir/s'
		.then (exists) ->
			shouldEqual exists, true

	it 'mkdirsSync', ->
		nofs.mkdirsSync 'test/fixtures/make/dir/s'
		exists = nofs.dirExistsSync 'test/fixtures/make/dir/s'
		shouldEqual exists, true

	it 'writeJson readJson', ->
		nofs.outputJson 'test/fixtures/json/json.json', { val: 'test' }
		.then ->
			nofs.readJson 'test/fixtures/json/json.json'
			.then (obj) ->
				shouldDeepEqual obj, { val: 'test' }

	it 'alias', ->
		nofs.ensureFile 'test/fixtures/alias/file/path'
		.then (created) ->
			shouldEqual created, true

	it 'glob', ->
		nofs.glob '**', {
			cwd: 'test/fixtures/dir'
		}
		.then (ls) ->
			shouldDeepEqual normalizePath(ls), [
				".", "a","test0","test0/b","test0/test1","test0/test1/c","test2","test2/d"
			]

	it 'globSync', ->
		ls = nofs.globSync '**', {
			cwd: 'test/fixtures/dir'
		}
		shouldDeepEqual normalizePath(ls), [
			".", "a","test0","test0/b","test0/test1","test0/test1/c","test2","test2/d"
		]

	it 'glob all', ->
		nofs.glob 'test/fixtures/dir/test2/**', { all: true }
		.then (ls) ->
			shouldDeepEqual normalizePath(ls), ["test/fixtures/dir/test2/.e","test/fixtures/dir/test2/d"]

	it 'globSync all', ->
		ls = nofs.globSync 'test/fixtures/dir/test2/**', { all: true }
		shouldDeepEqual normalizePath(ls), ["test/fixtures/dir/test2/.e","test/fixtures/dir/test2/d"]

	it 'glob a file', ->
		nofs.glob 'test/fixtures/sample.txt'
		.then (ls) ->
			shouldDeepEqual normalizePath(ls), ['test/fixtures/sample.txt']

	it 'globSync a file', ->
		ls = nofs.globSync 'test/fixtures/sample.txt'
		shouldDeepEqual normalizePath(ls), ['test/fixtures/sample.txt']

	it 'glob patterns', ->
		nofs.glob [
			'test/fixtures/dir/test2/**'
			'test/fixtures/dir/test0/**'
		]
		.then (ls) ->
			shouldDeepEqual normalizePath(ls), [
				"test/fixtures/dir/test0/b","test/fixtures/dir/test0/test1",
				"test/fixtures/dir/test0/test1/c","test/fixtures/dir/test2/d"
			]

	it 'globSync patterns', ->
		ls = nofs.globSync [
			'test/fixtures/dir/test2/**'
			'test/fixtures/dir/test0/**'
		]
		shouldDeepEqual normalizePath(ls), [
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
			shouldDeepEqual normalizePath(ls), [
				"test/fixtures/dir/test0/b","test/fixtures/dir/test0/test1",
				"test/fixtures/dir/test2/d"
			]

	it 'globSync negate patterns', ->
		ls = nofs.globSync [
			'test/fixtures/dir/test2/**'
			'test/fixtures/dir/test0/**'
			'!**/c'
		]
		shouldDeepEqual normalizePath(ls), [
			"test/fixtures/dir/test0/b","test/fixtures/dir/test0/test1",
			"test/fixtures/dir/test2/d"
		]

describe 'Watch:', ->
	it 'watchPath', (tdone) ->
		path = 'test/fixtures/watchFileTmp.txt'

		nofs.copySync 'test/fixtures/watchFile.txt', path
		nofs.watchPath path, {
			handler: (p, curr, prev, isDelete) ->
				return if isDelete
				shouldEqualDone tdone, p, path
		}
		wait().then ->
			nofs.outputFileSync path, 'test'

	it 'watchFiles', (tdone) ->
		path = 'test/fixtures/watchFilesTmp.txt'

		nofs.copySync 'test/fixtures/watchFile.txt', path
		nofs.watchFiles 'test/fixtures/**/*.txt', {
			handler: (p, curr, prev, isDelete) ->
				return if isDelete
				shouldEqualDone tdone, p, path
		}
		wait().then ->
			nofs.outputFileSync path, 'test'

	it 'watchDir modify', (tdone) ->
		tmp = 'test/fixtures/watchDirModify'

		nofs.copySync 'test/fixtures/watchDir', tmp
		nofs.watchDir tmp, {
			handler: (type, path) ->
				shouldDeepEqualDone tdone, { type, path }, {
					type: 'modify'
					path: tmp + '/dir0/c'
				}
		}
		wait().then ->
			nofs.outputFileSync tmp + '/dir0/c', 'ok'

	it 'watchDir create', (tdone) ->
		tmp = 'test/fixtures/watchDirCreate'

		nofs.copySync 'test/fixtures/watchDir', tmp
		nofs.watchDir tmp, {
			handler: (type, path) ->
				shouldDeepEqualDone tdone, { type, path }, {
					type: 'create'
					path: tmp + '/dir0/d'
				}
		}
		wait(1000).then ->
			nofs.outputFileSync tmp + '/dir0/d', 'ok'

	it 'watchDir delete', (tdone) ->
		tmp = 'test/fixtures/watchDirDelete'

		nofs.copySync 'test/fixtures/watchDir', tmp
		nofs.watchDir tmp, {
			handler: (type, path) ->
				shouldDeepEqualDone tdone, { type, path }, {
					type: 'delete'
					path: tmp + '/dir0/c'
				}
		}
		wait().then ->
			nofs.removeSync tmp + '/dir0/c'
