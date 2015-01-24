# [nofs](https://github.com/ysmood/nofs)

## Overview

`nofs` extends Node's native `fs` module with some useful methods. It tries
to make your functional programming experience better. It's one of the core
lib of [nokit][].

[![NPM version](https://badge.fury.io/js/nofs.svg)](http://badge.fury.io/js/nofs) [![Build Status](https://travis-ci.org/ysmood/nofs.svg)](https://travis-ci.org/ysmood/nofs) [![Build status](https://ci.appveyor.com/api/projects/status/11ddy1j4wofdhal7?svg=true)](https://ci.appveyor.com/project/ysmood/nofs)
 [![Deps Up to Date](https://david-dm.org/ysmood/nofs.svg?style=flat)](https://david-dm.org/ysmood/nofs)

## Features

- Introduce `map` and `reduce` to folders.
- Recursive `glob`, `move`, `copy`, `remove`, etc.
- **Promise** by default.
- Unified intuitive API. Support **Promise**, **Sync** and **Callback** paradigms.

## Install

```shell
npm install nofs
```

## API Convention

### Path & Pattern

Any path that can be a pattern it will do.

### Unix Path Separator

When the system is Windows and `process.env.force_unix_sep != 'off'`, nofs  will force all the path separator to `/`, such as `C:\a\b` will be transformed to `C:/a/b`.

### Promise, Sync and Callback

Any function that has a `Sync` version will has a promise version that ends with `P`.
For example the `fs.remove` will have `fs.removeSync` for sync IO, and `fs.removeP` for Promise.

### [eachDir](#eachDirP)

It is the core function for directory manipulation. Other abstract functions
like `mapDir`, `reduceDir`, `glob` are built on top of it. You can play
with it if you don't like other functions.

### nofs & Node Native fs

`nofs` only extends the native module, no pollution will be found. You can
still call `nofs.readFile` as easy as pie.

### Inheritance of Options

A Function's options may inherit other function's, especially the functions it calls internally. Such as the `glob` extends the `eachDir`'s
option, therefore `glob` also has a `filter` option.

## Quick Start

```coffee
# You can replace "require('fs')" with "require('nofs')"
fs = require 'nofs'


###
# Callback
###
fs.outputFile 'x.txt', 'test', (err) ->
    console.log 'done'


###
# Sync
###
fs.readFileSync 'x.txt'
fs.copySync 'dir/a', 'dir/b'


###
# Promise
###
fs.mkdirsP 'deep/dir/path'
.then ->
    fs.outputFileP 'a.txt', 'hello world'
.then ->
    fs.moveP 'dir/path', 'other'
.then ->
    fs.copyP 'one/**/*.js', 'two'
.then ->
    # Get all files, except js files.
    fs.globP ['deep/**', '!**/*.js']
.then (list) ->
    console.log list
.then ->
    # Remove only js files.
    fs.removeP 'deep/**/*.js'


###
# Concat all css files.
###
fs.reduceDirP 'dir/**/*.css', {
    init: '/* Concated by nofs */\n'
}, (sum, { path }) ->
    fs.readFileP(path).then (str) ->
        sum += str + '\n'
.then (concated) ->
    console.log concated


###
# Compile files from one place to another.
###
fs.mapDirP 'from', 'to', (src, dest) ->
    fs.readFileP(src, 'utf8').then (str) ->
        compiled = '/* Compiled by nofs */\n' + str
        fs.outputFileP dest, compiled



###
# Play with the low level api.
# Filter all the ignored files with high performance.
###
patterns = fs.readFileSync('.gitignore', 'utf8').split '\n'

filter = ({ path }) ->
    for ptn in patterns
        if fs.pmatch.minimath path, ptn
            return false
    return true

fs.eachDirP('.', {
    searchFilter: filter # Ensure subdirectory won't be searched.
    filter: filter
}, (info) ->
    info  # Directly return the file info object.
).then (tree) ->
    # Instead a list as usual,
    # here we get a file tree for further usage.
    console.log tree
```


## Works like Gulp

For more information see project [nokit][].

```coffee
fs = require 'nofs'

# coffee plugin
coffee = (path) ->
    fs.readFileP path, 'utf8'
    .then (coffee) ->
        # Unlike pipe, you can still control all the details esaily.
        '/* Add Lisence Info */\n\n' + coffee

# writer plugin: A simple curried function.
writer = (path) -> (js) ->
    fs.outputFileP path, js

# minify plugin
minify = (js) ->
    uglify = require 'uglify-js'
    uglify.minify js, { fromString: true }

# Use the plugins.
jsTask = ->
    # All files will be compiled concurrently.
    fs.mapDirP 'src/**/*.coffee', 'dist', (src, dest) ->
        # Here's the work flow, simple yet readable.
        coffee src
        .then minify
        .then writer(dest)

cssTask = -> # ...

cleanTask = -> # ...

# Run all tasks concurrently, and sequence groups.
compileGroup = [jsTask(), cssTask()]
fs.Promise.all compileGroup
.then cleanTask # The clean will work after all compilers are settled.
.then ->
    console.log 'All Done!'
```

## Changelog

Goto [changelog](doc/changelog.md)

## Function Alias

For some naming convention reasons, `nofs` also uses some common alias for fucntions. See [src/alias.coffee](src/alias.coffee).

## API

__No native `fs` funtion will be listed.__

- #### **[Promise](src/main.coffee?source#L15)**

    Here I use [Bluebird][Bluebird] only as an ES6 shim for Promise.
    No APIs other than ES6 spec will be used. In the
    future it will be removed.
    [Bluebird]: https://github.com/petkaantonov/bluebird

- #### **[copyDirP](src/main.coffee?source#L50)**

    Copy an empty directory.

    - **<u>param</u>**: `src` { _String_ }

    - **<u>param</u>**: `dest` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        ```coffee
        {
        	isForce: false
        	mode: auto
        }
        ```

    - **<u>return</u>**: { _Promise_ }

- #### **[copyFileP](src/main.coffee?source#L117)**

    Copy a single file.

    - **<u>param</u>**: `src` { _String_ }

    - **<u>param</u>**: `dest` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        ```coffee
        {
        	isForce: false
        	mode: auto
        }
        ```

    - **<u>return</u>**: { _Promise_ }

- #### **[copyP](src/main.coffee?source#L218)**

    Like `cp -r`.

    - **<u>param</u>**: `from` { _String_ }

        Source path.

    - **<u>param</u>**: `to` { _String_ }

        Destination path.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDirP-opts).
        Defaults:
        ```coffee
        {
        	# Overwrite file if exists.
        	isForce: false
        	isFnFileOnly: false
        }
        ```

    - **<u>return</u>**: { _Promise_ }

- #### **[dirExistsP](src/main.coffee?source#L291)**

    Check if a path exists, and if it is a directory.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>return</u>**: { _Promise_ }

        Resolves a boolean value.

- #### **[eachDirP](src/main.coffee?source#L406)**

    <a name='eachDirP'></a>
    Concurrently walks through a path recursively with a callback.
    The callback can return a Promise to continue the sequence.
    The resolving order is also recursive, a directory path resolves
    after all its children are resolved.

    - **<u>param</u>**: `spath` { _String_ }

        The path may point to a directory or a file.

    - **<u>param</u>**: `opts` { _Object_ }

        Optional. <a id='eachDirP-opts'></a> Defaults:
        ```coffee
        {
        	# Auto check if the spath is a minimatch pattern.
        	isAutoMimimatch: true

        	# Include entries whose names begin with a dot (.).
        	all: true

        	# To filter paths. It can also be a RegExp or a glob pattern string.
        	# When it's a string, it extends the Minimatch's options.
        	filter: (fileInfo) -> true

        	# The current working directory to search.
        	cwd: ''

        	# Call fn only when it is a file.
        	isFnFileOnly: false

        	# Whether to include the root directory or not.
        	isIncludeRoot: true

        	# Whehter to follow symbol links or not.
        	isFollowLink: true

        	# Iterate children first, then parent folder.
        	isReverse: false

        	# When isReverse is false, it will be the previous fn resolve value.
        	val: any

        	# If it return false, sub-entries won't be searched.
        	# When the `filter` option returns false, its children will
        	# still be itered. But when `searchFilter` returns false, children
        	# won't be itered by the fn.
        	searchFilter: (fileInfo) -> true

        	# If you want sort the names of each level, you can hack here.
        	# Such as `(names) -> names.sort()`.
        	handleNames: (names) -> names
        }
        ```

    - **<u>param</u>**: `fn` { _Function_ }

        `(fileInfo) -> Promise | Any`.
        The `fileInfo` object has these properties: `{ path, isDir, children, stats }`.
        Assume we call the function: `nofs.eachDirP('dir', (f) -> f)`,
        the resolved directory object array may look like:
        ```coffee
        {
        	path: 'dir/path'
        	name: 'path'
        	baseDir: 'dir'
        	isDir: true
        	val: 'test'
        	children: [
        		{ path: 'dir/path/a.txt', name: 'a.txt', baseDir: 'dir', isDir: false, stats: { ... } }
        		{ path: 'dir/path/b.txt', name: 'b.txt', baseDir: 'dir', isDir: false, stats: { ... } }
        	]
        	stats: {
        		size: 527
        		atime: Mon, 10 Oct 2011 23:24:11 GMT
        		mtime: Mon, 10 Oct 2011 23:24:11 GMT
        		ctime: Mon, 10 Oct 2011 23:24:11 GMT
        		...
        	}
        }
        ```
        The `stats` is a native `nofs.Stats` object.

    - **<u>return</u>**: { _Promise_ }

        Resolves a directory tree object.

    - **<u>example</u>**:

        ```coffee
        # Print all file and directory names, and the modification time.
        nofs.eachDirP 'dir/path', (obj, stats) ->
        	console.log obj.path, stats.mtime

        # Print path name list.
        nofs.eachDirP 'dir/path', (curr) -> curr
        .then (tree) ->
        	console.log tree

        # Find all js files.
        nofs.eachDirP 'dir/path', {
        	filter: '**/*.js', nocase: true
        }, ({ path }) ->
        	console.log paths

        # Find all js files.
        nofs.eachDirP 'dir/path', { filter: /\.js$/ }, ({ path }) ->
        	console.log paths

        # Custom filter
        nofs.eachDirP 'dir/path', {
        	filter: ({ path, stats }) ->
        		path.slice(-1) != '/' and stats.size > 1000
        }, (path) ->
        	console.log path
        ```

- #### **[fileExistsP](src/main.coffee?source#L615)**

    Check if a path exists, and if it is a file.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>return</u>**: { _Promise_ }

        Resolves a boolean value.

- #### **[globP](src/main.coffee?source#L666)**

    Get files by patterns.

    - **<u>param</u>**: `pattern` { _String | Array_ }

        The minimatch pattern.
        Patterns that starts with '!' in the array will be used
        to exclude paths.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDirP-opts).
        But the `filter` property will be fixed with the pattern.
        Defaults:
        ```coffee
        {
        	all: false

        	# The minimatch option object.
        	pmatch: {}
        }
        ```

    - **<u>param</u>**: `fn` { _Function_ }

        `(fileInfo, list) -> Promise | Any`.
        It will be called after each match. By default it is:
        `(fileInfo, list) -> list.push fileInfo.path`

    - **<u>return</u>**: { _Promise_ }

        Resolves the list array.

    - **<u>example</u>**:

        ```coffee
        # Get all js files.
        nofs.globP(['**/*.js', '**/*.css']).then (paths) ->
        	console.log paths

        # Exclude some files. "a.js" will be ignored.
        nofs.globP(['**/*.js', '!**/a.js']).then (paths) ->
        	console.log paths

        # Custom the iterator. Append '/' to each directory path.
        nofs.globP('**/*.js', (info, list) ->
        	list.push if info.isDir
        		info.path + '/'
        	else
        		info.path
        ).then (paths) ->
        	console.log paths
        ```

- #### **[mapDirP](src/main.coffee?source#L828)**

    Map file from a directory to another recursively with a
    callback.

    - **<u>param</u>**: `from` { _String_ }

        The root directory to start with.

    - **<u>param</u>**: `to` { _String_ }

        This directory can be a non-exists path.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDirP-opts). But `cwd` is
        fixed with the same as the `from` parameter. Defaults:
        ```coffee
        {
        	isFnFileOnly: true
        }
        ```

    - **<u>param</u>**: `fn` { _Function_ }

        `(src, dest, fileInfo) -> Promise | Any` The callback
        will be called with each path. The callback can return a `Promise` to
        keep the async sequence go on.

    - **<u>return</u>**: { _Promise_ }

        Resolves a tree object.

    - **<u>example</u>**:

        ```coffee
        # Copy and add license header for each files
        # from a folder to another.
        nofs.mapDirP(
        	'from'
        	'to'
        	(src, dest) ->
        		nofs.readFileP(src).then (buf) ->
        			buf += 'License MIT\n' + buf
        			nofs.outputFileP dest, buf
        )
        ```

- #### **[mkdirsP](src/main.coffee?source#L876)**

    Recursively create directory path, like `mkdir -p`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `mode` { _String_ }

        Defaults: `0o777 & ~process.umask()`

    - **<u>return</u>**: { _Promise_ }

- #### **[moveP](src/main.coffee?source#L918)**

    Moves a file or directory. Also works between partitions.
    Behaves like the Unix `mv`.

    - **<u>param</u>**: `from` { _String_ }

        Source path.

    - **<u>param</u>**: `to` { _String_ }

        Destination path.

    - **<u>param</u>**: `opts` { _Object_ }

        Defaults:
        ```coffee
        {
        	isForce: false
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        It will resolve a boolean value which indicates
        whether this action is taken between two partitions.

- #### **[outputFileP](src/main.coffee?source#L984)**

    Almost the same as `writeFile`, except that if its parent
    directories do not exist, they will be created.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `data` { _String | Buffer_ }

    - **<u>param</u>**: `opts` { _String | Object_ }

        <a id="outputFileP-opts"></a>
        Same with the [writeFile](#writeFile-opts).

    - **<u>return</u>**: { _Promise_ }

- #### **[outputJsonP](src/main.coffee?source#L1016)**

    Write a object to a file, if its parent directory doesn't
    exists, it will be created.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `obj` { _Any_ }

        The data object to save.

    - **<u>param</u>**: `opts` { _Object | String_ }

        Extends the options of [outputFileP](#outputFileP-opts).
        Defaults:
        ```coffee
        {
        	replacer: null
        	space: null
        }
        ```

    - **<u>return</u>**: { _Promise_ }

- #### **[path](src/main.coffee?source#L1038)**

    The native [io.js](iojs.org) path lib.

    - **<u>type</u>**: { _Object_ }

- #### **[pmatch](src/main.coffee?source#L1053)**

    The `minimatch` lib. It has two extra methods:
    - `isPmatch(String | Object) -> Pmatch | undefined`
        It helps to detect if a string or an object is a minimatch.

    - `getPlainPath(Pmatch) -> String`
        Helps to get the plain root path of a pattern. Such as `src/js/*.js`
        will get `src/js`

    [Documentation](https://github.com/isaacs/minimatch)

    [Offline Documentation](?gotoDoc=minimatch/readme.md)

- #### **[Promise](src/main.coffee?source#L1059)**

    What promise this lib is using.

    - **<u>type</u>**: { _Bluebird_ }

- #### **[promisify](src/main.coffee?source#L1066)**

    A callback style to promise helper.
    It doesn't depends on Bluebird.

    - **<u>type</u>**: { _Function_ }

- #### **[readJsonP](src/main.coffee?source#L1079)**

    Read A Json file and parse it to a object.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object | String_ }

        Same with the native `nofs.readFile`.

    - **<u>return</u>**: { _Promise_ }

        Resolves a parsed object.

    - **<u>example</u>**:

        ```coffee
        nofs.readJsonP('a.json').then (obj) ->
        	console.log obj.name, obj.age
        ```

- #### **[reduceDirP](src/main.coffee?source#L1115)**

    Walk through directory recursively with a callback.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDirP-opts),
        with some extra options:
        ```coffee
        {
        	# The init value of the walk.
        	init: undefined

        	isFnFileOnly: true
        }
        ```

    - **<u>param</u>**: `fn` { _Function_ }

        `(prev, path, isDir, stats) -> Promise`

    - **<u>return</u>**: { _Promise_ }

        Final resolved value.

    - **<u>example</u>**:

        ```coffee
        # Concat all files.
        nofs.reduceDirP 'dir/path', { init: '' }, (val, { path }) ->
        	nofs.readFileP(path).then (str) ->
        		val += str + '\n'
        .then (ret) ->
        	console.log ret
        ```

- #### **[removeP](src/main.coffee?source#L1157)**

    Remove a file or directory peacefully, same with the `rm -rf`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDirP-opts). But
        the `isReverse` is fixed with `true`.

    - **<u>return</u>**: { _Promise_ }

- #### **[touchP](src/main.coffee?source#L1196)**

    Change file access and modification times.
    If the file does not exist, it is created.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Default:
        ```coffee
        {
        	atime: Date.now()
        	mtime: Date.now()
        	mode: undefined
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        If new file created, resolves true.

- #### **[watchFileP](src/main.coffee?source#L1251)**

    <a id="writeFile-opts"></a>
    Watch a file. If the file changes, the handler will be invoked.
    You can change the polling interval by using `process.env.pollingWatch`.
    Use `process.env.watchPersistent = 'off'` to disable the persistent.
    Why not use `nofs.watch`? Because `nofs.watch` is unstable on some file
    systems, such as Samba or OSX.

    - **<u>param</u>**: `path` { _String_ }

        The file path

    - **<u>param</u>**: `handler` { _Function_ }

        Event listener.
        The handler has these params:
        - file path
        - current `nofs.Stats`
        - previous `nofs.Stats`
        - if its a deletion

    - **<u>param</u>**: `autoUnwatch` { _Boolean_ }

        Auto unwatch the file while file deletion.
        Default is true.

    - **<u>return</u>**: { _Promise_ }

        It resolves the wrapped watch listener.

    - **<u>example</u>**:

        ```coffee
        process.env.watchPersistent = 'off'
        nofs.watchFileP 'a.js', (path, curr, prev, isDeletion) ->
        	if curr.mtime != prev.mtime
        		console.log path
        ```

- #### **[watchFilesP](src/main.coffee?source#L1282)**

    Watch files, when file changes, the handler will be invoked.
    It is build on the top of `nofs.watchFileP`.

    - **<u>param</u>**: `patterns` { _Array_ }

        String array with minimatch syntax.
        Such as `['*/**.css', 'lib/**/*.js']`.

    - **<u>param</u>**: `handler` { _Function_ }

    - **<u>return</u>**: { _Promise_ }

        It contains the wrapped watch listeners.

    - **<u>example</u>**:

        ```coffee
        nofs.watchFiles '*.js', (path, curr, prev, isDeletion) ->
        	console.log path
        ```

- #### **[watchDirP](src/main.coffee?source#L1320)**

    Watch directory and all the files in it.
    It supports three types of change: create, modify, move, delete.
    By default, `move` event is disabled.
    It is build on the top of `nofs.watchFileP`.

    - **<u>param</u>**: `root` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Defaults:
        ```coffee
        {
        	pattern: '**' # minimatch, string or array

        	# Whether to watch POSIX hidden file.
        	all: false

        	# The minimatch options.
        	pmatch: {}

        	isEnableMoveEvent: false
        }
        ```

    - **<u>param</u>**: `fn` { _Function_ }

        `(type, path, oldPath) ->`.
        If the "path" ends with '/' it's a directory, else a file.

    - **<u>return</u>**: { _Promise_ }

        Resolves a object that keys are paths,
        values are listeners.

    - **<u>example</u>**:

        ```coffee
        # Only current folder, and only watch js and css file.
        nofs.watchDir 'lib', {
        	pattern: '*.+(js|css)'
        }, (type, path) ->
        		console.log type, path
        ```

- #### **[writeFileP](src/main.coffee?source#L1405)**

    A `writeFile` shim for `< Node v0.10`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `data` { _String | Buffer_ }

    - **<u>param</u>**: `opts` { _String | Object_ }

    - **<u>return</u>**: { _Promise_ }



## Benckmark

[`nofs.copy` vs `ncp`](benchmark/ncp.coffee)

## Lisence

MIT


[nokit]: https://github.com/ysmood/nokit