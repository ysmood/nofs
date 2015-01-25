Promise = require 'bluebird'

module.exports = _ =

	Promise: Promise

	promisify: (fn, self) ->
		(args...) ->
			if _.isFunction args[args.length - 1]
				return fn.apply self, args

			new Promise (resolve, reject) ->
				args.push ->
					if arguments[0]?
						reject arguments[0]
					else
						resolve arguments[1]
				fn.apply self, args

	callbackify: (fn, self) ->
		(args..., cb) ->
			if not _.isFunction cb
				args.push cb
				return fn.apply self, args

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

	isFunction: (val) -> typeof val == 'function'

	isObject: (val) -> typeof val == 'object'

	isRegExp: (val) -> val instanceof RegExp

	keys: (val) -> Object.keys val

	all: (arr, fn) ->
		for el, i in arr
			if fn(el, i) == false
				return false

		return true

	any: (arr, fn) ->
		for el, i in arr
			if fn(el, i) == true
				return true

		return false
