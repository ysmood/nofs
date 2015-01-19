nofs = require '../src/main'
{ Promise } = require '../src/utils'
npath = require 'path'

assert = require 'assert'

isWin = process.platform == 'win32'

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
		val.sort()
	else if typeof val == 'string'
		val

wait = (time = 500) ->
	new Promise (resolve) ->
		setTimeout ->
			resolve()
		, time

describe 'Basic:', ->
	it 'existsP', ->
		nofs.existsP('readme.md')
		.then (ret) ->
			shouldEqual ret, true

	it 'dirExistsP exists', ->
		nofs.dirExistsP('src').then (ret) ->
			shouldEqual ret, true

	it 'dirExistsP non-exists', ->
		nofs.dirExistsP('asdlkfjf').then (ret) ->
			shouldEqual ret, false

	it 'dirExistsSync', ->
		assert.equal nofs.dirExistsSync('src'), true

	it 'fileExistsP exists', ->
		nofs.fileExistsP('readme.md').then (ret) ->
			shouldEqual ret, true

	it 'fileExistsP non-exists', ->
		nofs.fileExistsP('src').then (ret) ->
			shouldEqual ret, false

	it 'fileExistsSync', ->
		assert.equal nofs.fileExistsSync('readme.md'), true

	it 'readFileP', ->
		nofs.readFileP 'test/fixtures/sample.txt', 'utf8'
		.then (ret) ->
			shouldEqual ret, 'test'

	it 'reduceDirP', ->
		nofs.reduceDirP 'test/fixtures/dir', {
			init: '', isReverse: true
		}, (sum, { path, isDir }) ->
			if isDir then sum else sum += path.slice(-1)
		.then (v) ->
			shouldEqual v.split('').sort().join(''), 'abcde'

	it 'reduceDirSync', ->
		v = nofs.reduceDirSync 'test/fixtures/dir', {
			init: '', isReverse: true
		}, (sum, { path, isDir }) ->
			if isDir then sum else sum += path.slice(-1)

		shouldEqual v.split('').sort().join(''), 'abcde'

	it 'eachDirP searchFilter', ->
		ls = []
		nofs.eachDirP 'test/fixtures/dir', {
			all: false
			searchFilter: ({ path }) ->
				normalizePath(path) != 'test/fixtures/dir/test0'
		}, (fileInfo) ->
			ls.push fileInfo.name
		.then ->
			shouldDeepEqual normalizePath(ls), ["a", "d", "dir", "test2"]

	it 'eachDirSync searchFilter', ->
		ls = []
		nofs.eachDirSync 'test/fixtures/dir', {
			searchFilter: ({ path }) ->
				normalizePath(path) != 'test/fixtures/dir/test0'
		}, (fileInfo) ->
			ls.push fileInfo.name
		shouldDeepEqual normalizePath(ls), [".e", "a", "d", "dir", "test2"]

	it 'removeP copyP moveP', ->
		after ->
			nofs.removeP 'test/fixtures/dirMV-p'

		nofs.removeP 'test/fixtures/dirCP-p'
		.then ->
			nofs.copyP 'test/fixtures/dir', 'test/fixtures/dirCP-p'
		.then ->
			nofs.moveP 'test/fixtures/dirCP-p', 'test/fixtures/dirMV-p'
		.then ->
			nofs.globP '**', {
				cwd: 'test/fixtures/dirMV-p'
			}
			.then (ls) ->
				shouldDeepEqual normalizePath(ls), [
					"a", "test0", "test0/b", "test0/test1"
					"test0/test1/c", "test2", "test2/d"
				]

	it 'removeSync copySync moveSync', ->
		after ->
			nofs.removeSync 'test/fixtures/dirMV-sync'

		nofs.removeSync 'test/fixtures/dirCP-sync'
		nofs.copySync 'test/fixtures/dir', 'test/fixtures/dirCP-sync'
		nofs.moveSync 'test/fixtures/dirCP-sync', 'test/fixtures/dirMV-sync'
		ls = nofs.globSync '**', {
			cwd: 'test/fixtures/dirMV-sync'
		}
		shouldDeepEqual normalizePath(ls), [
			"a", "test0", "test0/b", "test0/test1"
			"test0/test1/c", "test2", "test2/d"
		]

	it 'copyP moveP a file', ->
		after ->
			nofs.removeSync 'test/fixtures/copySample'
			nofs.removeSync 'test/fixtures/copySample2'

		nofs.copyP 'test/fixtures/sample.txt', 'test/fixtures/copySample/sample'
		.then ->
			nofs.moveP 'test/fixtures/copySample/sample', 'test/fixtures/copySample2/sample'
		.then ->
			nofs.fileExistsP 'test/fixtures/copySample2/sample'
			.then (exists) ->
				shouldEqual exists, true

	it 'copySync moveSync a file', ->
		after ->
			nofs.removeSync 'test/fixtures/copySampleSync'
			nofs.removeSync 'test/fixtures/copySampleSync2'

		nofs.copyP 'test/fixtures/sample.txt', 'test/fixtures/copySampleSync/sample'
		.then ->
			nofs.moveP 'test/fixtures/copySampleSync/sample', 'test/fixtures/copySampleSync2/sample'
		.then ->
			nofs.fileExistsP 'test/fixtures/copySampleSync2/sample'
			.then (exists) ->
				shouldEqual exists, true

	it 'touchP time', ->
		after ->
			nofs.removeSync 'test/fixtures/touchP'

		t = Date.now() // 1000
		nofs.touchP 'test/fixtures/touchP', {
			mtime: t
		}
		.then ->
			nofs.statP 'test/fixtures/touchP'
			.then (stats) ->
				shouldEqual stats.mtime.getTime() // 1000, t

	it 'touchSync time', ->
		after ->
			nofs.removeSync 'test/fixtures/touchSync'

		t = Date.now() // 1000
		nofs.touchSync 'test/fixtures/touchSync', {
			mtime: t
		}
		stats = nofs.statSync 'test/fixtures/touchSync'
		shouldEqual stats.mtime.getTime() // 1000, t

	it 'touchP create', ->
		after ->
			nofs.removeP 'test/fixtures/touchCreate'

		nofs.touchP 'test/fixtures/touchCreate'
		.then ->
			nofs.fileExistsP 'test/fixtures/touchCreate'
		.then (exists) ->
			shouldEqual exists, true

	it 'touchSync create', ->
		after ->
			nofs.removeSync 'test/fixtures/touchCreate'

		nofs.touchSync 'test/fixtures/touchCreate'
		exists = nofs.fileExistsSync 'test/fixtures/touchCreate'
		shouldEqual exists, true

	it 'outputFileP', ->
		after ->
			nofs.removeP 'test/fixtures/out'

		nofs.outputFileP 'test/fixtures/out/put/file', 'ok'
		.then ->
			nofs.readFileP 'test/fixtures/out/put/file', 'utf8'
		.then (str) ->
			shouldEqual str, 'ok'

	it 'outputFileSync', ->
		after ->
			nofs.removeSync 'test/fixtures/out'

		nofs.outputFileSync 'test/fixtures/out/put/file', 'ok'
		str = nofs.readFileSync 'test/fixtures/out/put/file', 'utf8'
		shouldEqual str, 'ok'

	it 'mkdirsP', ->
		after ->
			nofs.removeP 'test/fixtures/make'

		nofs.mkdirsP 'test/fixtures/make/dir/s'
		.then ->
			nofs.dirExistsP 'test/fixtures/make/dir/s'
		.then (exists) ->
			shouldEqual exists, true

	it 'mkdirsSync', ->
		after ->
			nofs.removeSync 'test/fixtures/make'

		nofs.mkdirsSync 'test/fixtures/make/dir/s'
		exists = nofs.dirExistsSync 'test/fixtures/make/dir/s'
		shouldEqual exists, true

	it 'writeJsonP readJsonP', ->
		after ->
			nofs.removeP 'test/fixtures/json'

		nofs.outputJsonP 'test/fixtures/json/json.json', { val: 'test' }
		.then ->
			nofs.readJsonP 'test/fixtures/json/json.json'
			.then (obj) ->
				shouldDeepEqual obj, { val: 'test' }

	it 'alias', ->
		after ->
			nofs.removeSync 'test/fixtures/alias'

		nofs.ensureFileP 'test/fixtures/alias/file/path'
		.then (created) ->
			shouldEqual created, true

	it 'globP', ->
		nofs.globP '**', {
			cwd: 'test/fixtures/dir'
		}
		.then (ls) ->
			shouldDeepEqual normalizePath(ls), [
				"a","test0","test0/b","test0/test1","test0/test1/c","test2","test2/d"
			]

	it 'globSync', ->
		ls = nofs.globSync '**', {
			cwd: 'test/fixtures/dir'
		}
		shouldDeepEqual normalizePath(ls), [
			"a","test0","test0/b","test0/test1","test0/test1/c","test2","test2/d"
		]

	it 'globP all', ->
		nofs.globP 'test/fixtures/dir/test2/**', { all: true }
		.then (ls) ->
			shouldDeepEqual normalizePath(ls), ["test/fixtures/dir/test2/.e","test/fixtures/dir/test2/d"]

	it 'globSync all', ->
		ls = nofs.globSync 'test/fixtures/dir/test2/**', { all: true }
		shouldDeepEqual normalizePath(ls), ["test/fixtures/dir/test2/.e","test/fixtures/dir/test2/d"]

	it 'globP a file', ->
		nofs.globP 'test/fixtures/sample.txt'
		.then (ls) ->
			shouldDeepEqual normalizePath(ls), ['test/fixtures/sample.txt']

	it 'globSync a file', ->
		ls = nofs.globSync 'test/fixtures/sample.txt'
		shouldDeepEqual normalizePath(ls), ['test/fixtures/sample.txt']

describe 'Watch:', ->
	it 'watchFileP', (tdone) ->
		path = 'test/fixtures/watchFileTmp.txt'

		after ->
			nofs.removeP path

		nofs.copyP 'test/fixtures/watchFile.txt', path
		.then ->
			nofs.watchFileP path, (p, curr, prev, isDelete) ->
				assert.equal p, path
				return if isDelete
				tdone()
		.then ->
			wait()
		.then ->
			nofs.outputFileSync path, 'test'

	it 'watchDirP modify', (tdone) ->
		tmp = 'test/fixtures/watchDirModify'
		after ->
			nofs.removeP tmp

		nofs.copyP 'test/fixtures/watchDir', tmp
		.then ->
			nofs.watchDirP tmp, (type, path) ->
				shouldDeepEqualDone tdone, { type, path }, {
					type: 'modify'
					path: tmp + '/dir0/c'
				}
		.then ->
			wait()
		.then ->
			nofs.outputFileSync tmp + '/dir0/c', 'ok'

	it 'watchDirP create', (tdone) ->
		tmp = 'test/fixtures/watchDirCreate'
		after ->
			nofs.removeP tmp

		nofs.copyP 'test/fixtures/watchDir', tmp
		.then ->
			nofs.watchDirP tmp, (type, path) ->
				shouldDeepEqualDone tdone, { type, path }, {
					type: 'create'
					path: tmp + '/dir0/d'
				}
		.then ->
			wait()
		.then ->
			nofs.outputFileSync tmp + '/dir0/d', 'ok'

	it 'watchDirP delete', (tdone) ->
		tmp = 'test/fixtures/watchDirDelete'
		after ->
			nofs.removeP tmp

		nofs.copyP 'test/fixtures/watchDir', tmp
		.then ->
			nofs.watchDirP tmp, (type, path) ->
				shouldDeepEqualDone tdone, { type, path }, {
					type: 'delete'
					path: tmp + '/dir0/c'
				}
			wait()
		.then ->
			nofs.removeP tmp + '/dir0/c'