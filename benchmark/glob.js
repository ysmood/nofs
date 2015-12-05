var glob, nodeGLob, pattern;

glob = require('glob');

pattern = '../**/*.js';

nodeGLob = function() {
  console.time('node-glob');
  return glob(pattern, {
    nosort: true,
    nounique: true
  }, function(err, files) {
    if (err) {
      return console.log(err);
    } else {
      console.timeEnd('node-glob');
      return console.log(files.length);
    }
  });
};

nodeGLob();
