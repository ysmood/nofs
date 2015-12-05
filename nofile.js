var kit;

kit = require('nokit');

kit.require('drives');

module.exports = function(task, option) {
    option('-g, --grep <pattern>', 'test pattern', '');
    option('-a, --all', 'clean all');

    task('default build', ['clean'], 'build project', function() {
        var compile, createDoc;
        compile = function() {
            return kit.warp('src/**').load(kit.drives.auto('compile')).run('dist');
        };
        createDoc = function() {
            return kit.warp('src/main.js').load(kit.drives.comment2md({
                tpl: 'doc/readme.jst.md'
            })).run();
        };
        return kit.async([compile(), createDoc()]);
    });

    task('lab l', 'lab', function() {
        return kit.monitorApp({
            args: ['test/lab.js']
        });
    });

    task('clean', function(opts) {
        if (opts.all) {
            return kit.async([kit.remove('dist'), kit.remove('.nokit')]);
        }
    });

    return task('test', 'run unit tests', function(opts) {
        var clean;
        clean = function() {
            return kit.spawn('git', ['clean', '-fd', kit.path.normalize('test/fixtures')]);
        };
        return clean().then(function() {
            return kit.spawn('junit', [
                'test/basic.js', '-g', opts.grep
            ]);
        }).then(function() {
            return clean();
        })["catch"](function(arg) {
            var code;
            code = arg.code;
            return process.exit(code);
        });
    });
};
