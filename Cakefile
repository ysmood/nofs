process.env.NODE_ENV = 'development'
process.chdir __dirname

kit = require 'nokit'
{ _ } = kit

task 'dev', 'Lab', ->
	kit.monitorApp {
		bin: 'coffee'
		args: ['test/lab.coffee']
	}

task 'build', 'Build project.', build = ->
	compileCoffee = ->
		kit.spawn 'coffee', [
			'-o', 'dist'
			'-cb', 'src'
		]

	createDoc = ->
		kit.compose([
			kit.parseFileComment 'src/main.coffee'
			(doc) ->
				tpl = kit.fs.readFileSync 'doc/readme.tpl.md', 'utf8'

				kit.outputFile 'readme.md', _.template tpl, { api: doc }
		])()

	start = kit.compose [
		-> kit.remove 'dist'
		compileCoffee
		createDoc
	]

	start().then ->
		kit.log 'Build done.'.green

option '-g', '--grep [grep]', 'Test pattern'
task 'test', 'Test', (opts) ->
	kit.spawn('mocha', [
		'-t', '5000'
		'-r', 'coffee-script/register'
		'-R', 'spec'
		'-g', opts.grep or '.'
		'test/basic.coffee'
	]).catch ({ code }) ->
		process.exit code
