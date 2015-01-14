Promise = require 'bluebird'

module.exports =

	Promise: Promise

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
			if arguments.length == 1
				args = [cb]
				cb == null

			fn.apply self, args
			.then (val) ->
				cb? null, val
			.catch (err) ->
				if cb
					cb err
				else
					Promise.reject err

	extend: (to, from) ->
		for k of from
			to[k] = from[k]
		to

	defaults: (to, from) ->
		for k of from
			if to[k] == undefined
				to[k] = from[k]
		to

	isString: (val) -> typeof val == 'string'

	isFunction: (val) -> typeof val == 'Function'

	isRegExp: (val) -> val instanceof RegExp

	keys: (val) -> Object.keys val
