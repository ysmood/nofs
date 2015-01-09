module.exports = (fs) ->

	aliasList = {
		touch: ['createFile', 'ensureFile']
		mkdirs: ['ensureDir', 'mkdirp']
		outputJson: ['outputJSON']
		readJson: ['readJSON']
		remove: ['delete']
		writeJson: ['writeJSON']
	}

	for k, list of aliasList
		for alias in list
			fs[alias] = fs[k]
			fs[alias + 'P'] = fs[k + 'P']
			fs[alias + 'Sync'] = fs[k + 'Sync']
