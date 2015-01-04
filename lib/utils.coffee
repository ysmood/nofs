Promise = require './bluebird/js/main/bluebird'

module.exports =

	promisify: (fn, self) ->
		(args...) ->
			new Promise (resolve, reject) ->
				args.push ->
					if arguments[0]?
						reject arguments[0]
					else
						resolve arguments[1]
				fn.apply self, args

	callbackify: (fn, self) ->
		(args..., cb) ->
			fn.apply self, args
			.then (val) ->
				cb null, val
			.catch cb

	extend: (to, from) ->
		for k of from
			to[k] = from[k]
		to

	defaults: (to, from) ->
		for k of from
			if to[k] == undefined
				to[k] = from[k]
		to
