var Promise = require('bluebird');

fs = require('fs');
gfs = require('graceful-fs');

for (k in gfs) {
	fs[k] = gfs[k];
}

fsx = require('fs-extra');


// Denodeify fs.
// Now we can call fs.readFileP with P support.
for (k in fsx) {
	if (k.slice(-4) == 'Sync') {
		var name = k.slice(0, -4);
		fs[name + 'P'] = Promise.promisify(fsx[name]);
	}
}

fs.moveP = Promise.promisify(fsx.move);

fs.existsP = function (path) {
	return new Promise(function(resolve) {
		fs.exists(path, function (exists) {
			resolve(exists);
		});
	});
}

fs.fileExists = function (path, cb) {
	fs.exists(path, function (exists) {
		if (exists) {
			fs.stat(path, function (err, stats) {
				cb(err, stats.isFile());
			});
		} else
			cb(null, false);
	});
}

fs.fileExistsSync = function (path) {
	if (fs.existsSync(path)) {
		return fs.statSync(path).isFile();
	} else
		return false;
}

fs.fileExistsP = Promise.promisify(fs.fileExists);

fs.dirExists = function (path, cb) {
	fs.exists(path, function (exists) {
		if (exists) {
			fs.stat(path, function (err, stats) {
				cb(err, stats.isDirectory());
			});
		} else
			cb(null, false);
	});
}

fs.dirExistsSync = function (path) {
	if (fs.existsSync(path)) {
		return fs.statSync(path).isDirectory();
	} else
		return false;
}

fs.dirExistsP = Promise.promisify(fs.dirExists);

module.exports = fs;
