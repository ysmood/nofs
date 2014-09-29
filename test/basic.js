fs = require('../lib/main');
var assert = require('assert');

describe('Basic:', function () {
	it('should work', function (tdone) {
		fs.existsP('readme.md').done(function (ret) {
			try {
				assert.equal(ret, true);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.moveP('test/move.txt', 'test/a.txt')
		.then(function () {
			assert.equal(fs.existsSync('test/a.txt'), true)
			return fs.moveP('test/a.txt', 'test/move.txt')
		}).then(tdone)['catch'](tdone);
	});

	it('should work', function (tdone) {
		fs.dirExistsP('lib').done(function (ret) {
			try {
				assert.equal(ret, true);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function () {
		assert.equal(
			fs.dirExistsSync('lib'),
			true
		)
	});

	it('should work', function () {
		assert.equal(
			fs.fileExistsSync('readme.md'),
			true
		)
	});

	it('should work', function (tdone) {
		fs.dirExistsP('readme.md').done(function (ret) {
			try {
				assert.equal(ret, false);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.fileExistsP('readme.md').done(function (ret) {
			try {
				assert.equal(ret, true);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.fileExistsP('lib').done(function (ret) {
			try {
				assert.equal(ret, false);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.readFileP('test/sample.txt', 'utf8').done(function (ret) {
			try {
				assert.equal(ret, 'test');
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.outputFileP('test/sample.txt', 'test').done(function () {
			tdone();
		});
	});
});
