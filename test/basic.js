require('../lib/main');
var assert = require('assert');

describe('Basic:', function () {
	it('should work', function (tdone) {
		fs.existsQ('readme.md').done(function (ret) {
			try {
				assert.equal(ret, true);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.dirExistsQ('lib').done(function (ret) {
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
		fs.dirExistsQ('readme.md').done(function (ret) {
			try {
				assert.equal(ret, false);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.fileExistsQ('readme.md').done(function (ret) {
			try {
				assert.equal(ret, true);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.fileExistsQ('lib').done(function (ret) {
			try {
				assert.equal(ret, false);
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});

	it('should work', function (tdone) {
		fs.readFileQ('test/sample.txt', 'utf8').done(function (ret) {
			try {
				assert.equal(ret, 'test');
				tdone();
			} catch (e) {
				tdone(e);
			}
		});
	});
});
