var Promise, isWin, kit, nofs, normalizePath, npath, regSep, wait;

process.env.pollingWatch = 30;

kit = require('nokit');

nofs = require('../src/main');

Promise = require('../src/utils').Promise;

npath = require('path');

isWin = process.platform === 'win32';

regSep = RegExp("" + ('\\' + npath.sep), "g");

normalizePath = function(val) {
    if (val instanceof Array) {
        return val.map(function(p) {
            return p.replace(regSep, '/');
        }).sort();
    } else if (typeof val === 'string') {
        return val.replace(regSep, '/');
    }
};

wait = function(time) {
    if (time == null) {
        time = 500;
    }
    return new Promise(function(resolve) {
        return setTimeout(function() {
            return resolve();
        }, time);
    });
};

module.exports = function(it) {

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

    it('copy', function() {
        var dir;
        dir = 'test/fixtures/dir-copy';
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
        dir = 'test/fixtures/dir-copySync';
        nofs.copySync('test/fixtures/dir', dir);
        ls = nofs.globSync('**', {
            cwd: dir
        });
        return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
    });

    it('copy self', function() {
        var dir;
        dir = 'test/fixtures/dir-copy-self';
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
        dir = 'test/fixtures/dir-copySync-self';
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
        dir = 'test/fixtures/dir-copy-pattern';
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
        dir = 'test/fixtures/dir-copySync-pattern';
        nofs.copySync('test/fixtures/dir/*0/**', dir);
        ls = nofs.globSync('**', {
            cwd: dir
        });
        return it.eq(normalizePath(ls), ["test0", "test0/b", "test0/test1", "test0/test1/c"]);
    });

    it('remove', function() {
        var dir;
        dir = 'test/fixtures/dir-remove';
        nofs.copySync('test/fixtures/dir', dir);
        return nofs.remove(dir).then(function() {
            return it.eq(nofs.dirExistsSync(dir), false);
        });
    });

    it('removeSync', function() {
        var dir;
        dir = 'test/fixtures/dir-removeSync';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.removeSync(dir);
        return it.eq(nofs.dirExistsSync(dir), false);
    });

    it('remove pattern', function() {
        var dir;
        dir = 'test/fixtures/dir-remove-pattern';
        nofs.copySync('test/fixtures/dir', dir);
        return nofs.remove('test/fixtures/dir-remove-pattern/test*').then(function() {
            return it.eq(normalizePath(nofs.globSync(dir + '/**')), ['test/fixtures/dir-remove-pattern/a']);
        });
    });

    it('removeSync pattern', function() {
        var dir;
        dir = 'test/fixtures/dir-removeSync-pattern';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.removeSync('test/fixtures/dir-removeSync-pattern/test*');
        return it.eq(normalizePath(nofs.globSync(dir + '/**')), ['test/fixtures/dir-removeSync-pattern/a']);
    });

    it('remove symbol link', function() {
        var dir;
        dir = 'test/fixtures/dir-remove-symbol-link';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.symlinkSync(dir + '/test0', dir + '/test0-link', 'dir');
        return nofs.remove(dir + '/test0-link').then(function() {
            return Promise.all([it.eq(nofs.dirExistsSync(dir + '/test0-link'), false), it.eq(nofs.dirExistsSync(dir + '/test0'), true)]);
        });
    });

    it('removeSync symbol link', function() {
        var dir;
        dir = 'test/fixtures/dir-removeSync-symbol-link';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.symlinkSync(dir + '/test0', dir + '/test0-link', 'dir');
        nofs.removeSync(dir + '/test0-link');
        return Promise.all([it.eq(nofs.dirExistsSync(dir + '/test0-link'), false), it.eq(nofs.dirExistsSync(dir + '/test0'), true)]);
    });

    it('remove race condition', function() {
        var dir;
        dir = 'test/fixtures/remove-race';
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
        dir = 'test/fixtures/dir-move';
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
        dir = 'test/fixtures/dir-moveSync';
        dir2 = dir + '2';
        nofs.copySync('test/fixtures/dir', dir);
        nofs.moveSync(dir, dir2);
        ls = nofs.globSync('**', {
            cwd: dir2
        });
        return it.eq(normalizePath(ls), ["a", "test0", "test0/b", "test0/test1", "test0/test1/c", "test2", "test2/d"]);
    });

    it('copy move a file', function() {
        return nofs.copy('test/fixtures/sample.txt', 'test/fixtures/copySample/sample').then(function() {
            return nofs.move('test/fixtures/copySample/sample', 'test/fixtures/copySample2/sample');
        }).then(function() {
            return nofs.fileExists('test/fixtures/copySample2/sample').then(function(exists) {
                return it.eq(exists, true);
            });
        });
    });

    it('copySync moveSync a file', function() {
        return nofs.copy('test/fixtures/sample.txt', 'test/fixtures/copySampleSync/sample').then(function() {
            return nofs.move('test/fixtures/copySampleSync/sample', 'test/fixtures/copySampleSync2/sample');
        }).then(function() {
            return nofs.fileExists('test/fixtures/copySampleSync2/sample').then(function(exists) {
                return it.eq(exists, true);
            });
        });
    });

    it('copy filter', function() {
        var dir;
        dir = 'test/fixtures/copyFilter';
        return nofs.copy('test/fixtures/dir', dir, {
            filter: '**/b'
        }).then(function() {
            return nofs.glob(dir + '/**');
        }).then(function(ls) {
            return it.eq(normalizePath(ls), ["test/fixtures/copyFilter/test0", "test/fixtures/copyFilter/test0/b"]);
        });
    });

    it('copySync filter', function() {
        var dir, ls;
        dir = 'test/fixtures/copyFilterSync';
        nofs.copySync('test/fixtures/dir', dir, {
            filter: '**/b'
        });
        ls = nofs.globSync(dir + '/**');
        return it.eq(normalizePath(ls), ["test/fixtures/copyFilterSync/test0", "test/fixtures/copyFilterSync/test0/b"]);
    });

    it('ensureFile', function() {
        return nofs.ensureFile('test/fixtures/ensureFile').then(function() {
            return nofs.fileExists('test/fixtures/ensureFile');
        }).then(function(exists) {
            return it.eq(exists, true);
        });
    });

    it('ensureFileSync', function() {
        var exists;
        nofs.ensureFileSync('test/fixtures/ensureFileSync');
        exists = nofs.fileExistsSync('test/fixtures/ensureFileSync');
        return it.eq(exists, true);
    });

    it('touch time', function() {
        var t;
        t = Math.floor(Date.now() / 1000);
        return nofs.touch('test/fixtures/touch', {
            mtime: t
        }).then(function() {
            return nofs.stat('test/fixtures/touch').then(function(stats) {
                return it.eq(Math.floor(stats.mtime.getTime() / 1000), t);
            });
        });
    });

    it('touchSync time', function() {
        var stats, t;
        t = Math.floor(Date.now() / 1000);
        nofs.touchSync('test/fixtures/touchSync', {
            mtime: t
        });
        stats = nofs.statSync('test/fixtures/touchSync');
        return it.eq(Math.floor(stats.mtime.getTime() / 1000), t);
    });

    it('touch create', function() {
        return nofs.touch('test/fixtures/touchCreate').then(function() {
            return nofs.fileExists('test/fixtures/touchCreate');
        }).then(function(exists) {
            return it.eq(exists, true);
        });
    });

    it('touchSync create', function() {
        var exists;
        nofs.touchSync('test/fixtures/touchCreate');
        exists = nofs.fileExistsSync('test/fixtures/touchCreate');
        return it.eq(exists, true);
    });

    it('outputFile', function() {
        return nofs.outputFile('test/fixtures/out/put/file', 'ok').then(function() {
            return nofs.readFile('test/fixtures/out/put/file', 'utf8');
        }).then(function(str) {
            return it.eq(str, 'ok');
        });
    });

    it('outputFileSync', function() {
        var str;
        nofs.outputFileSync('test/fixtures/out/put/file', 'ok');
        str = nofs.readFileSync('test/fixtures/out/put/file', 'utf8');
        return it.eq(str, 'ok');
    });

    it('mkdirs', function() {
        return nofs.mkdirs('test/fixtures/make/dir/s').then(function() {
            return nofs.dirExists('test/fixtures/make/dir/s');
        }).then(function(exists) {
            return it.eq(exists, true);
        });
    });

    it('mkdirsSync', function() {
        var exists;
        nofs.mkdirsSync('test/fixtures/make/dir/s');
        exists = nofs.dirExistsSync('test/fixtures/make/dir/s');
        return it.eq(exists, true);
    });

    it('outputJson readJson', function() {
        return nofs.outputJson('test/fixtures/json/json.json', {
            val: 'test'
        }).then(function() {
            return nofs.readJson('test/fixtures/json/json.json').then(function(obj) {
                return it.eq(obj, {
                    val: 'test'
                });
            });
        });
    });

    it('alias', function() {
        return nofs.createFile('test/fixtures/alias/file/path').then(function() {
            return nofs.fileExists('test/fixtures/alias/file/path');
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
        path = 'test/fixtures/watchFileTmpwatchPath.txt';
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
        var tmp = 'test/fixtures/watchFiles';
        var tmpFile = tmp + '/a';
        var pattern = 'test/fixtures/watchFiles/**';
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
        tmp = 'test/fixtures/watchDirModify';
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
        tmp = 'test/fixtures/watchDirCreate';
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
        tmp = 'test/fixtures/watchDirDelete';
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
};
