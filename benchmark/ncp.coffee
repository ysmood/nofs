###

"nofs.copy" vs "ncp"

ncp: 251ms
nofs: 259ms
copied file: 926
ratio: 2% slower
----------------------
ncp: 243ms
nofs: 268ms
copied file: 926
ratio: 9% slower
----------------------
ncp: 238ms
nofs: 210ms
copied file: 926
ratio: -13% slower

The trade off of using Promise is not that bad though.

###

ncp = require 'ncp'
nofs = require '../src/main'

largeDir = 'node_modules'

console.time('ncp')
t0 = Date.now()
ncp largeDir, 'test/fixtures/large-ncp', (err) ->
	if err
		console.log err
	else
		console.timeEnd('ncp')

	t1 = Date.now()

	count = 0
	console.time('nofs')
	nofs.copy largeDir, 'test/fixtures/large-nofs', {
		filter: ->
			count++
			true
	}
	.then ->
		console.timeEnd('nofs')

		t2 = Date.now()

		t_ncp = t1 - t0
		t_nofs = t2 - t1

		console.log 'copied file:', count
		console.log 'ratio:', ~~((t_nofs - t_ncp) / t_nofs * 100) + '%', 'slower'
	.then ->
		nofs.removeSync 'test/fixtures/large-ncp'
		nofs.removeSync 'test/fixtures/large-nofs'
