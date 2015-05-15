module.exports = (fs) ->

	aliasList = {
		# Origin    # Alias
		ensureFile: ['createFile']
		mkdirs:     ['ensureDir', 'mkdirp']
		outputJson: ['outputJSON']
		readJson:   ['readJSON']
		remove:     ['delete']
	}

	# Thus `nofs.touch` is the same with the `nofs.ensureFile`,
	# `nofs.touchSync` is the same with the `nofs.ensureFileSync`,
	# `nofs.touch` is the same with the `nofs.ensureFile`,
	for k, list of aliasList
		for alias in list
			fs[alias] = fs[k]
			fs[alias + 'Sync'] = fs[k + 'Sync']
