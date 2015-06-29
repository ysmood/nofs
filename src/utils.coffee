'use strict'

Promise = require 'yaku'

module.exports = _ =

	Promise: Promise

	PromiseUtils: require 'yaku/lib/utils'

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
