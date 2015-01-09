module.exports = (fs) ->

	aliasList = {
		# Origin    # Alias
		touch:      ['createFile', 'ensureFile']
		mkdirs:     ['ensureDir', 'mkdirp']
		outputJson: ['outputJSON']
		readJson:   ['readJSON']
		remove:     ['delete']
		writeJson:  ['writeJSON']
		readDirs:   ['readdirs']
	}

	# Thus `nofs.touch` is the same with the `nofs.ensureFile`,
	# `nofs.touchSync` is the same with the `nofs.ensureFileSync`,
	# `nofs.touchP` is the same with the `nofs.ensureFileP`,
	for k, list of aliasList
		for alias in list
			fs[alias] = fs[k]
			fs[alias + 'P'] = fs[k + 'P']
			fs[alias + 'Sync'] = fs[k + 'Sync']
