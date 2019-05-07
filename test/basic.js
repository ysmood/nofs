process.env.pollingWatch = 30;

var crypto = require('crypto');

var kit = require('nokit');

var nofs = require('../src/main');

var Promise = require('../src/utils').Promise;
Promise.enableLongStackTrace();

var npath = require('path');

var isWin = process.platform === 'win32';

var regSep = RegExp("" + ('\\' + npath.sep), "g");

function normalizePath (val) {
    if (val instanceof Array) {
        return val.map(function(p) {
            return p.replace(regSep, '/');
        }).sort();
    } else if (typeof val === 'string') {
        return val.replace(regSep, '/');
    }
};

function wait (time) {
    if (time == null) {
        time = 500;
    }
    return new Promise(function(resolve) {
        return setTimeout(function() {
            return resolve();
        }, time);
    });
};

function tempPath () {
    return 'test/temp/' + crypto.randomBytes(64).toString('hex');
}

kit.removeSync('test/temp');
kit.mkdirsSync('test/temp');

module.exports = function (it) {

    it('exists', function() {
        return nofs.exists('readme.md').then(function(ret) {
            return it.eq(ret, true);
        });
    });

    it('dirExists exists', function() {
        return nofs.dirExists('src').then(function(ret) {
            return it.eq(ret, true);
        });
    });

    it('dirExists non-exists', function() {
        return nofs.dirExists('asdlkfjf').then(function(ret) {
            return it.eq(ret, false);
        });
    });

    it('dirExistsSync', function() {
        return it.eq(nofs.dirExistsSync('src'), true);
    });

    it('fileExists exists', function() {
        return nofs.fileExists('readme.md').then(function(ret) {
            return it.eq(ret, true);
        });
    });

    it('fileExists non-exists', function() {
        return nofs.fileExists('src').then(function(ret) {
            return it.eq(ret, false);
        });
    });

    it('fileExistsSync', function() {
        return it.eq(nofs.fileExistsSync('readme.md'), true);
    });

    it('readFile', function() {
        return new Promise(function(resolve) {
            return nofs.readFile('test/fixtures/sample.txt', 'utf8', function(err, ret) {
                return resolve(it.eq(ret, 'test'));
            });
        });
    });

    it('readFile', function() {
        return nofs.readFile('test/fixtures/sample.txt', 'utf8').then(function(ret) {
            return it.eq(ret, 'test');
        });
    });

    it('readFile error', function() {
        return nofs.readFile('test/fixtures/dsfasdfas.txt', 'utf8').catch(function(err) {
            return it.eq(err.code, 'ENOENT');
        });
    });

    it('readFile error longStack', function() {
        return nofs.readFile('test/fixtures/dsfasdfas.txt', 'utf8').catch(function(err) {
            return it.eq(err.longStack.match('From previous Error').length, 1);
        });
    });

    it('reduceDir', function() {
        return nofs.reduceDir('test/fixtures/dir', {
            init: '',
            isReverse: true,
            iter: function(sum, arg) {
                var path;
                path = arg.path;
                return sum += path.slice(-1);
            }
        }).then(function(v) {
            return it.eq(v.split('').sort().join(''), 'abcde');
        });
    });

    it('reduceDirSync', function() {
        var v;
        v = nofs.reduceDirSync('test/fixtures/dir', {
            init: '',
            isReverse: true,
            iter: function(sum, arg) {
                var path;
                path = arg.path;
                return sum += path.slice(-1);
            }
        });
        return it.eq(v.split('').sort().join(''), 'abcde');
    });

    it('eachDir pattern with filter', function() {
        var ls;
        ls = [];
        return nofs.eachDir('test/fixtures/dir/**', {
            filter: function(arg) {
                var isDir;
                isDir = arg.isDir;
                return isDir;
            },
            iter: function(fileInfo) {
                return ls.push(fileInfo.name);
            }
        }).then(function() {
            return it.eq(normalizePath(ls), ['test0', 'test1', 'test2']);
        });
    });

    it('eachDirSync pattern with filter', function() {
        var ls;
        ls = [];
        nofs.eachDirSync('test/fixtures/dir/**', {
            filter: function(arg) {
                var isDir;
                isDir = arg.isDir;
                return isDir;
            },
            iter: function(fileInfo) {
                return ls.push(fileInfo.name);
            }
        });
        return it.eq(normalizePath(ls), ['test0', 'test1', 'test2']);
    });

    it('eachDir searchFilter', function() {
        var ls;
        ls = [];
        return nofs.eachDir('test/fixtures/dir', {
            all: false,
            searchFilter: function(arg) {
                var path;
                path = arg.path;
                return normalizePath(path) !== 'test/fixtures/dir/test0';
            },
            iter: function(fileInfo) {
                return ls.push(fileInfo.name);
            }
        }).then(function() {
            return it.eq(normalizePath(ls), ["a", "d", "dir", "test2"]);
        });
    });

    it('eachDirSync searchFilter', function() {
        var ls;
        ls = [];
        nofs.eachDirSync('test/fixtures/dir', {
            searchFilter: function(arg) {
                var path;
                path = arg.path;
                return normalizePath(path) !== 'test/fixtures/dir/test0';
            },
            iter: function(fileInfo) {
                return ls.push(fileInfo.name);
            }
        });
        return it.eq(normalizePath(ls), [".e", "a", "d", "dir", "test2"]);
    });

    it('mapDir pattern', function() {
        var ls;
        ls = [];
        return nofs.mapDir('test/fixtures/dir/*0/**', 'test/fixtures/other', {
            iter: function(src, dest) {
                return ls.push(src + '/' + dest);
            }
        }).then(function() {
            return it.eq(normalizePath(ls), ['test/fixtures/dir/test0/b/test/fixtures/other/test0/b', 'test/fixtures/dir/test0/test1/c/test/fixtures/other/test0/test1/c']);
        });
    });

    it('mapDirSync pattern', function() {
        var ls;
        ls = [];
        nofs.mapDirSync('test/fixtures/dir/*0/**', 'test/fixtures/other', {
            iter: function(src, dest) {
                return ls.push(src + '/' + dest);
            }
        });
        return it.eq(normalizePath(ls), ['test/fixtures/dir/test0/b/test/fixtures/other/test0/b', 'test/fixtures/dir/test0/test1/c/test/fixtures/other/test0/test1/c']);
    });

    it('mapDir pattern map content', function() {
        var dir = tempPath() + '/mapFiles';
        var now = Date.now() + '';
        return nofs.mapDir('test/fixtures/dir/*0/**', dir, {
            isMapContent: true,
            iter: function(content) {
                return now + content;
            }
        }).then(function() {
            return it.eq(kit.readFileSync(dir + '/test0/b') + '', now);
        });
    });

    it('mapDirSync pattern map content', function() {
        var dir = tempPath() + '/mapFilesSync';
        var now = Date.now() + '';
        nofs.mapDirSync('test/fixtures/dir/*0/**', dir, {
            isMapContent: true,
            iter: function(content) {
                return now + content;
            }
        });

        return it.eq(kit.readFileSync(dir + '/test0/b') + '', now);
    });

    it('copy', function() {
        var dir = tempPath() + '/fixtures/dir-copy';
        return nofs.copy('test/fixtures/dir', dir).then(function() {
            return nofs.glob('**', {
                cwd: dir
            });
        }).then(function(ls) {
            return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
        });
    });

    it('copySync', function() {
        var dir, ls;
        dir = tempPath() + '/dir-copySync';
        nofs.copySync('test/fixtures/dir', dir);
        ls = nofs.globSync('**', {
            cwd: dir
        });
        return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
    });

    it('copy self', function() {
        var dir;
        dir = tempPath() + '/dir-copy-self';
        nofs.mkdirsSync(dir);
        return nofs.copy('test/fixtures/dir/**', dir).then(function() {
            return nofs.glob('**', {
                cwd: dir
            });
        }).then(function(ls) {
            return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
        });
    });

    it('copySync self', function() {
        var dir;
        dir = tempPath() + '/dir-copySync-self';
        nofs.mkdirsSync(dir);
        nofs.copySync('test/fixtures/dir/**', dir);
        return nofs.glob('**', {
            cwd: dir
        }).then(function(ls) {
            return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
        });
    });

    it('copy pattern', function() {
        var dir;
        dir = tempPath() + '/dir-copy-pattern';
        return nofs.copy('test/fixtures/dir/*0/**', dir).then(function() {
            return nofs.glob('**', {
                cwd: dir
            });
        }).then(function(ls) {
            return it.eq(normalizePath(ls), ["test0", "test0/b", "test0/test1", "test0/test1/c"]);
        });
    });

    it('copySync pattern', function() {
        var dir, ls;
        dir = tempPath() + '/dir-copySync-pattern';
        nofs.copySync('test/fixtures/dir/*0/**', dir);
        ls = nofs.globSync('**', {
            cwd: dir
        });
        return it.eq(normalizePath(ls), ["test0", "test0/b", "test0/test1", "test0/test1/c"]);
    });

    it('remove', function() {
        var dir;
        dir = tempPath() + '/dir-remove';
        nofs.copySync('test/fixtures/dir', dir);
        return nofs.remove(dir).then(function() {
            return it.eq(nofs.dirExistsSync(dir), false);
        });
    });

    it('removeSync', function() {
        var dir;
        dir = tempPath() + '/dir-removeSync';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.removeSync(dir);
        return it.eq(nofs.dirExistsSync(dir), false);
    });

    it('remove pattern', function() {
        var dir;
        dir = tempPath() + '/dir-remove-pattern';
        nofs.copySync('test/fixtures/dir', dir);
        return nofs.remove(dir + '/test*').then(function() {
            return it.eq(normalizePath(nofs.globSync(dir + '/**')), [dir + '/a']);
        });
    });

    it('removeSync pattern', function() {
        var dir;
        dir = tempPath() + '/dir-removeSync-pattern';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.removeSync(dir + '/test*');
        return it.eq(normalizePath(nofs.globSync(dir + '/**')), [dir + '/a']);
    });

    it('remove symbol link', function() {
        var dir;
        dir = tempPath() + '/dir-remove-symbol-link';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.symlinkSync(dir + '/test0', dir + '/test0-link', 'dir');
        return nofs.remove(dir + '/test0-link').then(function() {
            return Promise.all([it.eq(nofs.dirExistsSync(dir + '/test0-link'), false), it.eq(nofs.dirExistsSync(dir + '/test0'), true)]);
        });
    });

    it('removeSync symbol link', function() {
        var dir;
        dir = tempPath() + '/dir-removeSync-symbol-link';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.symlinkSync(dir + '/test0', dir + '/test0-link', 'dir');
        nofs.removeSync(dir + '/test0-link');
        return Promise.all([it.eq(nofs.dirExistsSync(dir + '/test0-link'), false), it.eq(nofs.dirExistsSync(dir + '/test0'), true)]);
    });

    it('remove race condition', function() {
        var dir;
        dir = tempPath() + '/remove-race';
        nofs.mkdirsSync(dir);
        nofs.touchSync(dir + '/a');
        nofs.touchSync(dir + '/b');
        nofs.touchSync(dir + '/c');
        return Promise.all([nofs.remove(dir), nofs.remove(dir + '/a'), nofs.remove(dir + '/b'), nofs.remove(dir + '/c')]).then(function() {
            return it.eq(nofs.dirExistsSync(dir), false);
        });
    });

    it('move', function() {
        var dir, dir2;
        dir = tempPath() + '/dir-move';
        dir2 = dir + '2';
        return nofs.copy('test/fixtures/dir', dir).then(function() {
            return nofs.move(dir, dir2);
        }).then(function() {
            return nofs.glob('**', {
                cwd: dir2
            }).then(function(ls) {
                return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
            });
        });
    });

    it('moveSync', function() {
        var dir, dir2, ls;
        dir = tempPath() + '/dir-moveSync';
        dir2 = dir + '2';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.moveSync(dir, dir2);
        ls = nofs.globSync('**', {
            cwd: dir2
        });
        return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
    });

    it('copy move a file', function() {
        var dir = tempPath();
        return nofs.copy('test/fixtures/sample.txt', dir + '/sample.txt')
        .then(function() {
            return nofs.move(dir + '/sample.txt', dir + '/sample2.txt');
        }).then(function() {
            return it.eq(nofs.fileExists(dir + '/sample2.txt'), true);
        });
    });

    it('copySync moveSync a file', function() {
        var dir = tempPath();

        nofs.copySync('test/fixtures/sample.txt', dir + '/sample.txt');
        nofs.moveSync(dir + '/sample.txt', dir + '/sample2.txt');

        return it.eq(nofs.fileExists(dir + '/sample2.txt'), true);
    });

    it('copy filter', function() {
        var dir;
        dir = tempPath();
        return nofs.copy('test/fixtures/dir', dir, {
            filter: function (f) {
                return /b$/.test(f.path);
            }
        }).then(function() {
            return nofs.glob(dir + '/**');
        }).then(function(ls) {
            return it.eq(normalizePath(ls), [dir + "/test0", dir + "/test0/b"]);
        });
    });

    it('copySync filter', function() {
        var dir, ls;
        dir = tempPath();
        nofs.copySync('test/fixtures/dir', dir, {
            filter: function (f) {
                return /b$/.test(f.path);
            }
        });
        ls = nofs.globSync(dir + '/**');
        return it.eq(normalizePath(ls), [dir + "/test0", dir + "/test0/b"]);
    });

    it('copy pattern filter', function() {
        var dir;
        dir = tempPath();
        return nofs.copy('test/fixtures/dir/**', dir, {
            filter: function (f) {
                return /b$/.test(f.path);
            }
        }).then(function() {
            return nofs.glob(dir + '/**');
        }).then(function(ls) {
            return it.eq(normalizePath(ls), [dir + "/test0", dir + "/test0/b"]);
        });
    });

    it('copySync pattern filter', function() {
        var dir, ls;
        dir = tempPath();
        nofs.copySync('test/fixtures/dir/**', dir, {
            filter: function (f) {
                return /b$/.test(f.path);
            }
        });
        ls = nofs.globSync(dir + '/**');
        return it.eq(normalizePath(ls), [dir + "/test0", dir + "/test0/b"]);
    });

    it('copy pattern', function() {
        var dir;
        dir = tempPath();
        return nofs.copy('test/fixtures/dir/**/*b', dir).then(function() {
            return nofs.glob(dir + '/**');
        }).then(function(ls) {
            return it.eq(normalizePath(ls), [dir + "/test0", dir + "/test0/b"]);
        });
    });

    it('copySync pattern', function() {
        var dir, ls;
        dir = tempPath();
        nofs.copySync('test/fixtures/dir/**/*b', dir);
        ls = nofs.globSync(dir + '/**');
        return it.eq(normalizePath(ls), [dir + "/test0", dir + "/test0/b"]);
    });

    it('ensureFile', function() {
        var path = tempPath();
        return nofs.ensureFile(path).then(function() {
            return nofs.fileExists(path);
        }).then(function(exists) {
            return it.eq(exists, true);
        });
    });

    it('ensureFileSync', function() {
        var path = tempPath();
        nofs.ensureFileSync(path);
        var exists = nofs.fileExistsSync(path);
        return it.eq(exists, true);
    });

    it('touch time', function() {
        var t = Math.floor(new Date("2019-01-01T00:00:00.000Z").getTime() / 1000);
        var path = tempPath();
        return nofs.touch(path, {
            mtime: t
        }).then(function() {
            return nofs.stat(path).then(function(stats) {
                return it.eq(Math.floor(stats.mtime.getTime() / 1000), t);
            });
        });
    });

    it('touchSync time', function() {
        var stats, t;
        var path = tempPath();
        var t = Math.floor(new Date("2019-02-01T00:00:00.000Z").getTime() / 1000);
        nofs.touchSync(path, {
            mtime: t
        });
        stats = nofs.statSync(path);
        return it.eq(Math.floor(stats.mtime.getTime() / 1000), t);
    });

    it('touch create', function() {
        var path = tempPath();
        return nofs.touch(path).then(function() {
            return nofs.fileExists(path);
        }).then(function(exists) {
            return it.eq(exists, true);
        });
    });

    it('touchSync create', function() {
        var exists;
        var path = tempPath();
        nofs.touchSync(path);
        exists = nofs.fileExistsSync(path);
        return it.eq(exists, true);
    });

    it('outputFile', function() {
        var path = tempPath() + '/out/out/put/file'
        return nofs.outputFile(path, 'ok').then(function() {
            return nofs.readFile(path, 'utf8');
        }).then(function(str) {
            return it.eq(str, 'ok');
        });
    });

    it('outputFile number', function() {
        var path = tempPath() + '/out/out/put/file'
        return nofs.outputFile(path, 123).then(function() {
            return nofs.readFile(path, 'utf8');
        }).then(function(str) {
            return it.eq(str, '123');
        });
    });

    it('outputFileSync', function() {
        var path = tempPath() + '/out/out/put/file'
        var str;
        nofs.outputFileSync(path, 'ok');
        str = nofs.readFileSync(path, 'utf8');
        return it.eq(str, 'ok');
    });

    it('mkdirs', function() {
        var path = tempPath() + '/deep/deep/path/'
        return nofs.mkdirs(path).then(function() {
            return nofs.dirExists(path);
        }).then(function(exists) {
            return it.eq(exists, true);
        });
    });

    it('mkdirsSync', function() {
        var path = tempPath() + '/deep/deep/path/'
        var exists;
        nofs.mkdirsSync(path);
        exists = nofs.dirExistsSync(path);
        return it.eq(exists, true);
    });

    it('outputJson readJson', function() {
        var path = tempPath() + '/out/out/put/file.json'
        return nofs.outputJson(path, {
            val: 'test'
        }).then(function() {
            return nofs.readJson(path).then(function(obj) {
                return it.eq(obj, {
                    val: 'test'
                });
            });
        });
    });

    it('outputJsonSync readJsonSync', function() {
        var path = tempPath() + '/out/out/put/file.json'

        nofs.outputJsonSync(path, {
            val: 'test'
        });

        return it.eq(nofs.readJsonSync(path), {
            val: 'test'
        });
    });

    it('alias', function() {
        var path = tempPath() +  '/alias/file/path';
        return nofs.createFile(path).then(function() {
            return nofs.fileExists(path);
        }).then(function(exists) {
            return it.eq(exists, true);
        });
    });

    it('glob', function() {
        return nofs.glob('**', {
            cwd: 'test/fixtures/dir'
        }).then(function(ls) {
            return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
        });
    });

    it('globSync', function() {
        var ls;
        ls = nofs.globSync('**', {
            cwd: 'test/fixtures/dir'
        });
        return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
    });

    it('glob non-exists', function() {
        return nofs.glob('aaaaaaaaaaaaaa').then(function(ls) {
            return it.eq(normalizePath(ls), []);
        });
    });

    it('globSync non-exists', function() {
        var ls;
        ls = nofs.globSync('aaaaaaaaaaaaaa');
        return it.eq(normalizePath(ls), []);
    });

    it('glob all', function() {
        return nofs.glob('test/fixtures/dir/test2/**', {
            all: true
        }).then(function(ls) {
            return it.eq(normalizePath(ls), ["test/fixtures/dir/test2/.e", "test/fixtures/dir/test2/d"]);
        });
    });

    it('globSync all', function() {
        var ls;
        ls = nofs.globSync('test/fixtures/dir/test2/**', {
            all: true
        });
        return it.eq(normalizePath(ls), ["test/fixtures/dir/test2/.e", "test/fixtures/dir/test2/d"]);
    });

    it('glob a file', function() {
        return nofs.glob('./test/fixtures/sample.txt').then(function(ls) {
            return it.eq(normalizePath(ls), ['test/fixtures/sample.txt']);
        });
    });

    it('globSync a file', function() {
        var ls;
        ls = nofs.globSync('./test/fixtures/sample.txt');
        return it.eq(normalizePath(ls), ['test/fixtures/sample.txt']);
    });

    it('glob patterns', function() {
        return nofs.glob(['test/fixtures/dir/test2/**', 'test/fixtures/dir/test0/**']).then(function(ls) {
            return it.eq(normalizePath(ls), ["test/fixtures/dir/test0/b", "test/fixtures/dir/test0/test1", "test/fixtures/dir/test0/test1/c", "test/fixtures/dir/test2/d"]);
        });
    });

    it('globSync patterns', function() {
        var ls;
        ls = nofs.globSync(['test/fixtures/dir/test2/**', 'test/fixtures/dir/test0/**']);
        return it.eq(normalizePath(ls), ["test/fixtures/dir/test0/b", "test/fixtures/dir/test0/test1", "test/fixtures/dir/test0/test1/c", "test/fixtures/dir/test2/d"]);
    });

    it('glob negate patterns', function() {
        return nofs.glob(['test/fixtures/dir/test2/**', 'test/fixtures/dir/test0/**', '!**/c']).then(function(ls) {
            return it.eq(normalizePath(ls), ["test/fixtures/dir/test0/b", "test/fixtures/dir/test0/test1", "test/fixtures/dir/test2/d"]);
        });
    });

    it('globSync negate patterns', function() {
        var ls;
        ls = nofs.globSync(['test/fixtures/dir/test2/**', 'test/fixtures/dir/test0/**', '!**/c']);
        return it.eq(normalizePath(ls), ["test/fixtures/dir/test0/b", "test/fixtures/dir/test0/test1", "test/fixtures/dir/test2/d"]);
    });

    it('watchPath', function() {
        var path;
        path = tempPath() + '/file.txt';
        return new Promise(function(resolve) {
            nofs.copySync('test/fixtures/watchFile.txt', path);
            nofs.watchPath(path, {
                handler: function(p, curr, prev, isDelete) {
                    if (isDelete) {
                        return;
                    }
                    return resolve(it.eq(normalizePath(p), path));
                }
            });
            return wait().then(function() {
                return nofs.outputFileSync(path, 'test');
            });
        }).then(function() {
            return nofs.unwatchFile(path);
        });
    });

    it('watchFiles', function() {
        var tmp = tempPath();
        var tmpFile = tmp + '/a';
        var pattern = tmp + '/**';
        return new Promise(function(resolve) {
            nofs.copySync('test/fixtures/watchDir', tmp);
            nofs.watchFiles(pattern, {
                handler: function(p, curr, prev, isDelete) {
                    if (isDelete) {
                        return;
                    }
                    resolve(it.eq(normalizePath(p), tmpFile));
                }
            });
            return wait().then(function() {
                return nofs.outputFileSync(tmpFile, 'test');
            });
        }).then(function() {
            var i, len, ref, results, p;
            ref = nofs.globSync(pattern);
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
                p = ref[i];
                results.push(nofs.unwatchFile(p));
            }
            return results;
        });
    });

    it('watchDir modify', function() {
        var tmp;
        tmp = tempPath();
        return new Promise(function(resolve) {
            nofs.copySync('test/fixtures/watchDir', tmp);
            nofs.watchDir(tmp, {
                patterns: '*',
                handler: function(type, path) {
                    return resolve(it.eq({
                        type: type,
                        path: normalizePath(path)
                    }, {
                        type: 'modify',
                        path: tmp + '/a'
                    }));
                }
            });
            return wait().then(function() {
                return nofs.outputFileSync(tmp + '/a', 'ok');
            });
        }).then(function() {
            var i, len, path, ref, results;
            nofs.unwatchFile(tmp);
            ref = nofs.globSync(tmp + '/*');
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
                path = ref[i];
                results.push(nofs.unwatchFile(path));
            }
            return results;
        });
    });

    it('watchDir create', function() {
        var tmp;
        tmp = tempPath();
        return new Promise(function(resolve) {
            nofs.copySync('test/fixtures/watchDir', tmp);
            nofs.watchDir(tmp, {
                patterns: ['/dir0/*'],
                handler: function(type, path, oldPath, stats) {
                    return resolve(it.eq({
                        type: type,
                        path: normalizePath(path),
                        isDir: stats.isDirectory()
                    }, {
                        type: 'create',
                        path: tmp + '/dir0/d',
                        isDir: false
                    }));
                }
            });
            return wait(1000).then(function() {
                return nofs.outputFileSync(tmp + '/dir0/d', 'ok');
            });
        }).then(function() {
            var i, len, path, ref, results;
            nofs.unwatchFile(tmp);
            nofs.unwatchFile(tmp + '/dir0');
            ref = nofs.globSync(tmp + '/dir0/*');
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
                path = ref[i];
                results.push(nofs.unwatchFile(path));
            }
            return results;
        });
    });

    it('watchDir delete', function() {
        var tmp;
        tmp = tempPath();
        return new Promise(function(resolve) {
            nofs.copySync('test/fixtures/watchDir', tmp);
            nofs.watchDir(tmp, {
                patterns: ['**', '!a'],
                handler: function(type, path) {
                    return resolve(it.eq({
                        type: type,
                        path: normalizePath(path)
                    }, {
                        type: 'delete',
                        path: tmp + '/dir0/c'
                    }));
                }
            });
            return wait().then(function() {
                nofs.removeSync(tmp + '/a');
                return nofs.removeSync(tmp + '/dir0/c');
            });
        }).then(function() {
            var i, len, path, ref, results;
            nofs.unwatchFile(tmp);
            ref = nofs.globSync(tmp + '/**');
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
                path = ref[i];
                results.push(nofs.unwatchFile(path));
            }
            return results;
        });
    });

    it('watchDir delete dir', function() {
        var tmp;
        tmp = tempPath();
        return new Promise(function(resolve) {
            nofs.copySync('test/fixtures/watchDir', tmp);
            nofs.watchDir(tmp, {
                patterns: ['**', '!a'],
                handler: function(type, path, oldPath, stats, oldStats) {
                    if (kit._.endsWith(path, 'c')) return;

                    return resolve(it.eq({
                        type: type,
                        path: normalizePath(path),
                        isDirectory: false,
                        isOldDirectory: true
                    }, {
                        type: 'delete',
                        path: tmp + '/dir0',
                        isDirectory: stats.isDirectory(),
                        isOldDirectory: oldStats.isDirectory()
                    }));
                }
            });
            return wait().then(function() {
                nofs.removeSync(tmp + '/dir0');
            });
        }).then(function() {
            var i, len, path, ref, results;
            nofs.unwatchFile(tmp);
            ref = nofs.globSync(tmp + '/**');
            results = [];
            for (i = 0, len = ref.length; i < len; i++) {
                path = ref[i];
                results.push(nofs.unwatchFile(path));
            }
            return results;
        });
    });
};
