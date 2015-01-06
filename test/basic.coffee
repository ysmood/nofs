fs = require '../lib/main'
{ Promise } = require '../lib/utils'

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

	it 'dirExists', ->
		fs.dirExists 'lib', (err, ret) ->
			shouldEqual ret, true

	it 'dirExistsP', ->
		fs.dirExistsP('lib').then (ret) ->
			shouldEqual ret, true

	it 'dirExistsP', ->
		fs.dirExistsP('asdlkfjf').then (ret) ->
			shouldEqual ret, false

	it 'dirExistsSync', ->
		assert.equal fs.dirExistsSync('lib'), true

	it 'fileExistsSync', ->
		assert.equal fs.fileExistsSync('readme.md'), true

	it 'fileExistsP', ->
		fs.fileExistsP('readme.md').then (ret) ->
			shouldEqual ret, true

	it 'fileExistsP', ->
		fs.fileExistsP('lib').then (ret) ->
			shouldEqual ret, false

	it 'readFileP', ->
		fs.readFileP 'test/fixtures/sample.txt', 'utf8'
		.then (ret) ->
			shouldEqual ret, 'test'

	it 'readdirsP', ->
		fs.readdirsP 'test/fixtures/dir'
		.then (ls) ->
			shouldDeepEqual ls, [
				'test/fixtures/dir/a'
				'test/fixtures/dir/test/'
				'test/fixtures/dir/test/b'
			]

	# it 'removeSync', ->
	# 	fs.removeSync 'test/fixtures/removeTemp'

	# it 'mkdirsSync', (tdone) ->
	# 	fs.mkdirsSync 'test/fixtures/mk/dirs'

	# it 'moveP', (tdone) ->
	# 	fs.moveP 'test/fixtures/move.txt', 'test/fixtures/a.txt'
	# 	.then ->
	# 		assert.equal fs.existsSync('test/fixtures/a.txt'), true
	# 		fs.moveP('test/fixtures/a.txt', 'test/fixtures/move.txt')
	# 	.then tdone
	# 	.catch tdone

	# it 'outputFileP', (tdone) ->
	# 	fs.outputFileP('test/fixtures/sample.txt', 'test')
	# 	.then ->
	# 		tdone()
	# 	.catch tdone

	# it 'outputFileSync', (tdone) ->
	# 	fs.outputFileSync('test/fixtures/sample.txt', 'test')
	# 	tdone()
