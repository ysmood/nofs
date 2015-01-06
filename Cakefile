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
			kit.readFile 'src/main.coffee', 'utf8'
			(code) ->
				kit.parseComment 'fs-more', code, 'src/main.coffee'
			(nofsModule) ->
				indent = (str, num = 0) ->
					s = _.range(num).reduce ((s) -> s + ' '), ''
					s + str.trim().replace(/\n/g, '\n' + s)

				modsApi = ''

				for modName, mod of { nofs: nofsModule }
					modsApi += """### #{modName}\n\n"""
					for method in mod
						method.name = method.name.replace 'self.', ''
						sourceLink = "#{method.path}?source#L#{method.line}"
						methodStr = indent """
							- #### <a href="#{sourceLink}" target="_blank"><b>#{method.name}</b></a>
						"""
						methodStr += '\n\n'
						if method.description
							methodStr += indent method.description, 2
							methodStr += '\n\n'

						if _.any(method.tags, { tagName: 'private' })
							continue

						for tag in method.tags
							tname = if tag.name then "`#{tag.name}`" else ''
							ttype = if tag.type then "{ _#{tag.type}_ }" else ''
							methodStr += indent """
								- **<u>#{tag.tagName}</u>**: #{tname} #{ttype}
							""", 2
							methodStr += '\n\n'
							if tag.description
								methodStr += indent tag.description, 4
								methodStr += '\n\n'

						modsApi += methodStr

				tpl = kit.fs.readFileSync 'doc/readme.tpl.md', 'utf8'

				kit.outputFile 'readme.md', _.template tpl, { api: modsApi }
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
		'-g', opts.grep or ''
		'test/basic.coffee'
	]).catch ({ code }) ->
		process.exit code
