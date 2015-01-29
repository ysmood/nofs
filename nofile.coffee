process.chdir __dirname

task 'default', ['build'], 'Default task is "build"'

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
				tpl = kit.readFileSync 'doc/readme.tpl.md', 'utf8'

				kit.outputFile 'readme.md', _.template(tpl)({ api: doc })
		])()

	start = kit.compose [
		-> kit.remove 'dist'
		-> kit.copy 'src/**/*.js', 'dist'
		compileCoffee
		createDoc
	]

	start().then ->
		kit.log 'Build done.'.green

option '-g, --grep [pattern]', 'Test pattern', '.'
task 'test', 'Test', (opts) ->
	clean = ->
		kit.spawn 'git', ['clean', '-fd', kit.path.normalize('test/fixtures')]

	clean()
	.then ->
		kit.spawn('mocha', [
			'-t', '5000'
			'-r', 'coffee-script/register'
			'-R', 'spec'
			'-g', opts.grep
			'test/basic.coffee'
		])
	.then -> clean()
	.catch ({ code }) ->
		process.exit code
