var fs = require('../lib/main');

fs.readFileP('readme.md', 'utf8').then(function (val) {
	console.log(val);
}).catch(function (err) {
	console.log(err);
});
