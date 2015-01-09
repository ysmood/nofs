# "nofs.copy" vs "ncp"
#
# About 18,828 items, 300MB transfered.
# nofs: 5407ms
# ncp: 8489ms
#
# nofs is only about 36.3% slower. The trade off of using Promise is not the bottle neck.

ncp = require 'ncp'
nofs = require '../src/main'

console.time('ncp')
t0 = Date.now()
ncp 'large', 'test/fixtures/large-ncp', (err) ->
	if err
		console.log err
	else
		console.timeEnd('ncp')

	t1 = Date.now()

	console.time('nofs')
	nofs.copyP 'large', 'test/fixtures/large-nofs'
	.then ->
		console.timeEnd('nofs')

		t2 = Date.now()

		t_ncp = t1 - t0
		t_nofs = t2 - t1

		console.log 'ratio:', (t_nofs - t_ncp) / t_nofs