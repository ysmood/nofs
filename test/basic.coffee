fs = require '../lib/main'
{ Promise } = require '../lib/utils'
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
		fs.existsP('readme.md')
		.then (ret) ->
			shouldEqual ret, true

	it 'dirExistsP exists', ->
		fs.dirExistsP('lib').then (ret) ->
			shouldEqual ret, true

	it 'dirExistsP non-exists', ->
		fs.dirExistsP('asdlkfjf').then (ret) ->
			shouldEqual ret, false

	it 'dirExistsSync', ->
		assert.equal fs.dirExistsSync('lib'), true

	it 'fileExistsSync', ->
		assert.equal fs.fileExistsSync('readme.md'), true

	it 'fileExistsP exists', ->
		fs.fileExistsP('readme.md').then (ret) ->
			shouldEqual ret, true

	it 'fileExistsP non-exists', ->
		fs.fileExistsP('lib').then (ret) ->
			shouldEqual ret, false

	it 'readFileP', ->
		fs.readFileP 'test/fixtures/sample.txt', 'utf8'
		.then (ret) ->
			shouldEqual ret, 'test'

	it 'reduceDirP', ->
		fs.reduceDirP 'test/fixtures/dir', {
			init: '', isReverse: true, isCacheStats: true
		}, (sum, p, s) ->
			if s.isFile()
				sum += p.slice -1
			else
				sum
		.then (v) ->
			shouldEqual v, 'drba'

	it 'readdirsP', ->
		fs.readdirsP 'test/fixtures/dir'
		.then (ls) ->
			shouldDeepEqual ls, [
				'test/fixtures/dir/a'
				'test/fixtures/dir/test/'
				'test/fixtures/dir/test2/'
				'test/fixtures/dir/test/b'
				'test/fixtures/dir/test/test/'
				'test/fixtures/dir/test2/r'
				'test/fixtures/dir/test/test/d'
			]

	it 'readdirsP cwd filter', ->
		fs.readdirsP '', {
			cwd: 'test/fixtures/dir'
			filter: new RegExp("[^#{npath.sep}]$")
		}
		.then (ls) ->
			shouldDeepEqual ls, ["a","test/b","test2/r","test/test/d"]

	it 'removeP copyP moveP', ->
		after ->
			fs.removeP 'test/fixtures/dirMV'

		fs.removeP 'test/fixtures/dirCP'
		.then ->
			fs.copyP 'test/fixtures/dir', 'test/fixtures/dirCP'
		.then ->
			fs.moveP 'test/fixtures/dirCP', 'test/fixtures/dirMV'
		.then ->
			fs.readdirsP '', {
				cwd: 'test/fixtures/dirMV'
			}
			.then (ls) ->
				shouldDeepEqual ls, [
					'a', 'test/', 'test2/', 'test/b', 'test/test/', 'test2/r', 'test/test/d'
				]

	it 'touchP time', ->
		t = Date.now() // 1000
		fs.touchP 'test/fixtures/sample.txt', {
			mtime: t
		}
		.then ->
			fs.statP 'test/fixtures/sample.txt'
			.then (stats) ->
				shouldEqual stats.mtime.getTime() // 1000, t

	it 'touchP create', ->
		after ->
			fs.removeP 'test/fixtures/touchCreate'

		fs.touchP 'test/fixtures/touchCreate'
		.then ->
			fs.fileExistsP 'test/fixtures/touchCreate'
		.then (exists) ->
			shouldEqual exists, true

	it 'outputFileP', ->
		after ->
			fs.removeP 'test/fixtures/out'

		fs.outputFileP 'test/fixtures/out/put/file', 'ok'
		.then ->
			fs.readFileP 'test/fixtures/out/put/file', 'utf8'
		.then (str) ->
			shouldEqual str, 'ok'

	it 'mkdirsP', ->
		after ->
			fs.removeP 'test/fixtures/make'

		fs.mkdirsP 'test/fixtures/make/dir/s'
		.then ->
			fs.dirExistsP 'test/fixtures/make/dir/s'
		.then (exists) ->
			shouldEqual exists, true
