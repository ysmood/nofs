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

	it 'fileExistsSync', ->
		assert.equal nofs.fileExistsSync('readme.md'), true

	it 'fileExistsP exists', ->
		nofs.fileExistsP('readme.md').then (ret) ->
			shouldEqual ret, true

	it 'fileExistsP non-exists', ->
		nofs.fileExistsP('src').then (ret) ->
			shouldEqual ret, false

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

	it 'readDirsP', ->
		nofs.readDirsP 'test/fixtures/dir'
		.then (ls) ->
			shouldDeepEqual ls.sort(), [
				'test/fixtures/dir'
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

	it 'removeP copyP moveP', ->
		after ->
			nofs.removeP 'test/fixtures/dirMV'

		nofs.removeP 'test/fixtures/dirCP'
		.then ->
			nofs.copyP 'test/fixtures/dir', 'test/fixtures/dirCP'
		.then ->
			nofs.moveP 'test/fixtures/dirCP', 'test/fixtures/dirMV'
		.then ->
			nofs.readDirsP '', {
				cwd: 'test/fixtures/dirMV'
			}
			.then (ls) ->
				shouldDeepEqual ls.sort(), [
					"", "a", "test0", "test0/b", "test0/test1"
					"test0/test1/c", "test2", "test2/d"
				]

	it 'touchP time', ->
		t = Date.now() // 1000
		nofs.touchP 'test/fixtures/sample.txt', {
			mtime: t
		}
		.then ->
			nofs.statP 'test/fixtures/sample.txt'
			.then (stats) ->
				shouldEqual stats.mtime.getTime() // 1000, t

	it 'touchP create', ->
		after ->
			nofs.removeP 'test/fixtures/touchCreate'

		nofs.touchP 'test/fixtures/touchCreate'
		.then ->
			nofs.fileExistsP 'test/fixtures/touchCreate'
		.then (exists) ->
			shouldEqual exists, true

	it 'outputFileP', ->
		after ->
			nofs.removeP 'test/fixtures/out'

		nofs.outputFileP 'test/fixtures/out/put/file', 'ok'
		.then ->
			nofs.readFileP 'test/fixtures/out/put/file', 'utf8'
		.then (str) ->
			shouldEqual str, 'ok'

	it 'mkdirsP', ->
		after ->
			nofs.removeP 'test/fixtures/make'

		nofs.mkdirsP 'test/fixtures/make/dir/s'
		.then ->
			nofs.dirExistsP 'test/fixtures/make/dir/s'
		.then (exists) ->
			shouldEqual exists, true
