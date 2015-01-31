'use strict'

minimatch = require 'minimatch'

_ = require './utils'

_.extend minimatch, {

	###*
	 * Check if a string is a minimatch pattern.
	 * @param  {String | Object}
	 * @return {Pmatch | undefined}
	###
	isPmatch: (target) ->
		if _.isString target
			return if not target

			pm = new minimatch.Minimatch target
			if minimatch.isNotPlain pm
				return pm
		else if target instanceof minimatch.Minimatch
			target

	isNotPlain: (pm) ->
		pm.set.length > 1 or !_.all(pm.set[0], _.isString)

	matchMultiple: (patterns, opts) ->
		# Hanle negate patterns.
		# Only when there are both negate and non-negate patterns,
		# the exclusion will work.
		negates = []
		pmatches = []
		if not opts.nonegate
			for p in patterns
				(if p[0] == '!' then negates else pmatches).push p

			if pmatches.length == 0
				pmatches = negates
				negates = []
		pmatches = pmatches.map (p) -> new minimatch.Minimatch(p, opts)
		negates = if negates.length == 0
			null
		else
			negates.map (p) -> new minimatch.Minimatch(p[1..], opts)

		match = (path, partial) ->
			_.any pmatches, (pm) -> pm.match path, partial

		negateMath = (path, partial) ->
			return if not negates
			_.any negates, (pm) -> pm.match path, partial

		{ pmatches, negateMath, match }

	###*
	 * Get the plain path of the pattern.
	 * @param  {Pmatch} pm
	 * @return {String}
	###
	getPlainPath: (pm) ->
		paths = pm.set.map (p) ->
			plain = []
			for s in p
				if _.isString s
					plain.push s
				else
					return plain
			plain

		if paths.length == 1
			res = paths[0]
		else
			l = Math.min.apply(0, paths.map (p) -> p.length)

			rest = paths[1..]
			res = []
			for i in [0...l]
				base = paths[0][i]
				same = true
				for p in rest
					if p[i] != base
						same = false
						continue
				if same
					res.push p[i]
		res.join '/'
}

module.exports = minimatch
