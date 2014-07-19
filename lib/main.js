var Q = require('q');
gfs = require('graceful-fs');
fs = require('fs-extra');

for (k in gfs) {
	fs[k] = gfs[k];
}

// Denodeify fs.
// Now we can call fs.readFileQ with Q support.
for (k in fs) {
	if (k.slice(-4) == 'Sync') {
		var name = k.slice(0, -4);
		fs[name + 'Q'] = Q.denodeify(fs[name]);
	}
}

fs.existsQ = function (path) {
	var defer = Q.defer();
	fs.exists(path, function (exists) {
		defer.resolve(exists);
	});
	return defer.promise;
}

fs.fileExistsQ = function (path) {
	return fs.existsQ(path).then(function (exists) {
		if (exists) {
			return fs.statQ(path).then(function (stats) {
				return stats.isFile();
			});
		}
		else
			return false;
	});
}

fs.dirExistsQ = function (path) {
	return fs.existsQ(path).then(function (exists) {
		if (exists) {
			return fs.statQ(path).then(function (stats) {
				return stats.isDirectory();
			});
		}
		else
			return false;
	});
}
