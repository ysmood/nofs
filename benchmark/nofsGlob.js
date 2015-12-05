var nofs, nofsGlob, pattern;

nofs = require('../src/main');

pattern = '../**/*.js';

nofsGlob = function() {
  console.time('nofs-glob');
  return nofs.glob(pattern, {
    isFollowLink: false
  }).then(function(files) {
    console.timeEnd('nofs-glob');
    console.log(files.length);
    return files;
  });
};

nofsGlob();
