nofs = require '../src/main'
{ Promise } = require '../src/utils'
npath = require 'path'

assert = require 'assert'

shouldEqual = (args...) ->
	try
		assert.strictEqual.apply assert, args
	catch err
		Promise.reject err

shouldDeepEqual = (args...) ->
	try
		assert.deepEqual.apply assert, args
	catch err
		Promise.reject err

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
			shouldEqual v.split('').sort().join(''), 'abcd'

	it 'reduceDirSync', ->
		v = nofs.reduceDirSync 'test/fixtures/dir', {
			init: '', isReverse: true
		}, (sum, { path, isDir }) ->
			if isDir then sum else sum += path.slice(-1)

		shouldEqual v.split('').sort().join(''), 'abcd'

	it 'readDirsP', ->
		nofs.readDirsP 'test/fixtures/dir'
		.then (ls) ->
			shouldDeepEqual ls.sort(), [
				'test/fixtures/dir/a'
				'test/fixtures/dir/test0'
				'test/fixtures/dir/test0/b'
				'test/fixtures/dir/test0/test1'
				'test/fixtures/dir/test0/test1/c'
				'test/fixtures/dir/test2'
				'test/fixtures/dir/test2/d'
			]

	it 'readDirsSync', ->
		ls = nofs.readDirsSync 'test/fixtures/dir'
		shouldDeepEqual ls.sort(), [
			'test/fixtures/dir/a'
			'test/fixtures/dir/test0'
			'test/fixtures/dir/test0/b'
			'test/fixtures/dir/test0/test1'
			'test/fixtures/dir/test0/test1/c'
			'test/fixtures/dir/test2'
			'test/fixtures/dir/test2/d'
		]

	it 'readDirsP cwd filter', ->
		nofs.readDirsP '', {
			cwd: 'test/fixtures/dir'
			filter: /[a-z]{1}$/
		}
		.then (ls) ->
			shouldDeepEqual ls.sort(), [
				"a", "test0/b", "test0/test1/c", "test2/d"
			]

	it 'readDirsSync cwd filter', ->
		ls = nofs.readDirsSync '', {
			cwd: 'test/fixtures/dir'
			filter: /[a-z]{1}$/
		}
		shouldDeepEqual ls.sort(), [
			"a", "test0/b", "test0/test1/c", "test2/d"
		]

	it 'readDirsSync cwd minimatch', ->
		ls = nofs.readDirsSync '', {
			cwd: 'test/fixtures/dir'
			filter: '**/{a,b,c}'
		}
		shouldDeepEqual ls.sort(), [
			"a", "test0/b", "test0/test1/c"
		]

	it 'removeP copyP moveP', ->
		after ->
			nofs.removeP 'test/fixtures/dirMV-p'

		nofs.removeP 'test/fixtures/dirCP-p'
		.then ->
			nofs.copyP 'test/fixtures/dir', 'test/fixtures/dirCP-p'
		.then ->
			nofs.moveP 'test/fixtures/dirCP-p', 'test/fixtures/dirMV-p'
		.then ->
			nofs.readDirsP '', {
				cwd: 'test/fixtures/dirMV-p'
			}
			.then (ls) ->
				shouldDeepEqual ls.sort(), [
					"a", "test0", "test0/b", "test0/test1"
					"test0/test1/c", "test2", "test2/d"
				]

	it 'removeSync copySync moveSync', ->
		after ->
			nofs.removeSync 'test/fixtures/dirMV-sync'

		nofs.removeSync 'test/fixtures/dirCP-sync'
		nofs.copySync 'test/fixtures/dir', 'test/fixtures/dirCP-sync'
		nofs.moveSync 'test/fixtures/dirCP-sync', 'test/fixtures/dirMV-sync'
		ls = nofs.readDirsSync '', {
			cwd: 'test/fixtures/dirMV-sync'
		}
		shouldDeepEqual ls.sort(), [
			"a", "test0", "test0/b", "test0/test1"
			"test0/test1/c", "test2", "test2/d"
		]

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
		nofs.globP '**/*.txt', {
			cwd: 'test/fixtures/'
		}
		.then (list) ->
			shouldDeepEqual list, ["sample.txt"]

	it 'globSync', ->
		list = nofs.globSync '**/*.txt', {
			cwd: 'test/fixtures/'
		}
		shouldDeepEqual list, ["sample.txt"]
