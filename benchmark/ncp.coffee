# nofs vs ncp

ncp = require 'ncp'
nofs = require '../src/main'

console.time('ncp')
ncp 'test/fixtures/large', 'test/fixtures/large-ncp', (err) ->
	if err
		console.log err
	else
		console.timeEnd('ncp')

	console.time('nofs')
	nofs.copyP 'test/fixtures/large', 'test/fixtures/large-nofs'
	.then ->
		console.timeEnd('nofs')