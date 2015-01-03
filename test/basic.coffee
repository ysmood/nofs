fs = require '../lib/main'
assert = require 'assert'

describe 'Basic:', ->
	it 'existsP', (tdone) ->
		fs.existsP('readme.md')
		.then (ret) ->
			assert.equal ret, true
			tdone()
		.catch tdone

	it 'moveP', (tdone) ->
		fs.moveP 'test/fixtures/move.txt', 'test/fixtures/a.txt'
		.then ->
			assert.equal fs.existsSync('test/fixtures/a.txt'), true
			fs.moveP('test/fixtures/a.txt', 'test/fixtures/move.txt')
		.then tdone
		.catch tdone

	it 'dirExistsP', (tdone) ->
		fs.dirExistsP('lib').then (ret) ->
			assert.equal ret, true
			tdone()

	it 'dirExistsSync', ->
		assert.equal fs.dirExistsSync('lib'), true

	it 'fileExistsSync', ->
		assert.equal fs.fileExistsSync('readme.md'), true

	it 'dirExistsP', (tdone) ->
		fs.dirExistsP('readme.md').then (ret) ->
			assert.equal ret, false
			tdone()

	it 'fileExistsP', (tdone) ->
		fs.fileExistsP('readme.md').then (ret) ->
			assert.equal(ret, true)
			tdone()

	it 'fileExistsP', (tdone) ->
		fs.fileExistsP('lib').then (ret) ->
			assert.equal(ret, false)
			tdone()

	it 'readFileP', (tdone) ->
		fs.readFileP 'test/fixtures/sample.txt', 'utf8'
		.then (ret) ->
			assert.equal(ret, 'test')
			tdone()

	it 'outputFileP', (tdone) ->
		fs.outputFileP('test/fixtures/sample.txt', 'test')
		.then ->
			tdone()
		.catch tdone

	it 'outputFileSync', (tdone) ->
		fs.outputFileSync('test/fixtures/sample.txt', 'test')
		tdone()
