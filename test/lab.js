var Promise, nofs, npath;

nofs = require('../src/main');

npath = require('path');

Promise = require('../src/utils').Promise;

nofs.watchPath('test/basic.js', {
  handler: function(path) {
    return console.log(path);
  }
});
