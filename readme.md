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
- Unified intuitive API. Supports both **Promise**, **Sync** and **Callback** paradigms.
- Very light weight. Only depends on `bluebird` and `minimath`.

## Install

```shell
npm install nofs
```

## API Convention

### Path & Pattern

Any path that can be a pattern it will do.

### Promise & Callback

If you call an async function without callback, it will return a promise.
For example the `nofs.remove('dir', -> 'done!' )` are the same with
`nofs.remove('dir').then -> 'done!'`.

### [eachDir](#eachDir)

It is the core function for directory manipulation. Other abstract functions
like `mapDir`, `reduceDir`, `glob` are built on top of it. You can play
with it if you don't like other functions.

### nofs & Node Native fs

Only the callback of `nofs.exists`
is slightly different, it will also gets two arguments `(err, exists)`.

`nofs` only extends the native module, no pollution will be found. You can
still require the native `fs`, and call `fs.exists` as easy as pie.

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
fs.mkdirs 'deep/dir/path'
.then ->
    fs.outputFile 'a.txt', 'hello world'
.then ->
    fs.move 'dir/path', 'other'
.then ->
    fs.copy 'one/**/*.js', 'two'
.then ->
    # Get all files, except js files.
    fs.glob ['deep/**', '!**/*.js']
.then (list) ->
    console.log list
.then ->
    # Remove only js files.
    fs.remove 'deep/**/*.js'


###
# Concat all css files.
###
fs.reduceDir 'dir/**/*.css', {
    init: '/* Concated by nofs */\n'
    iter: (sum, { path }) ->
        fs.readFile(path).then (str) ->
            sum += str + '\n'
}
.then (concated) ->
    console.log concated



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

fs.eachDir('.', {
    searchFilter: filter # Ensure subdirectory won't be searched.
    filter: filter
    iter: (info) -> info  # Directly return the file info object.
}).then (tree) ->
    # Instead a list as usual,
    # here we get a file tree for further usage.
    console.log tree
```


## Changelog

Goto [changelog](doc/changelog.md)

## Function Alias

For some naming convention reasons, `nofs` also uses some common alias for fucntions. See [src/alias.coffee](src/alias.coffee).

## API

__No native `fs` funtion will be listed.__

- ### **[Promise](src/main.coffee?source#L11)**

    Here I use [Bluebird](https://github.com/petkaantonov/bluebird) only as an ES6 shim for Promise.
    No APIs other than ES6 spec will be used. In the
    future it will be removed.

- ### **[copyDir](src/main.coffee?source#L49)**

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

- ### **[copyFile](src/main.coffee?source#L116)**

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

- ### **[copy](src/main.coffee?source#L217)**

    Like `cp -r`.

    - **<u>param</u>**: `from` { _String_ }

        Source path.

    - **<u>param</u>**: `to` { _String_ }

        Destination path.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDir-opts).
        Defaults:
        ```coffee
        {
        	# Overwrite file if exists.
        	isForce: false
        	isIterFileOnly: false
        }
        ```

    - **<u>return</u>**: { _Promise_ }

- ### **[dirExists](src/main.coffee?source#L290)**

    Check if a path exists, and if it is a directory.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>return</u>**: { _Promise_ }

        Resolves a boolean value.

- ### **[eachDir](src/main.coffee?source#L428)**

    <a name='eachDir'></a>
    Concurrently walks through a path recursively with a callback.
    The callback can return a Promise to continue the sequence.
    The resolving order is also recursive, a directory path resolves
    after all its children are resolved.

    - **<u>param</u>**: `spath` { _String_ }

        The path may point to a directory or a file.

    - **<u>param</u>**: `opts` { _Object_ }

        Optional. <a id='eachDir-opts'></a> Defaults:
        ```coffee
        {
        	# Callback on each path iteration.
        	iter: (fileInfo) -> Promise | Any

        	# Auto check if the spath is a minimatch pattern.
        	isAutoMimimatch: true

        	# Include entries whose names begin with a dot (.), the posix hidden files.
        	all: true

        	# To filter paths. It can also be a RegExp or a glob pattern string.
        	# When it's a string, it extends the Minimatch's options.
        	filter: (fileInfo) -> true

        	# The current working directory to search.
        	cwd: ''

        	# Call iter only when it is a file.
        	isIterFileOnly: false

        	# Whether to include the root directory or not.
        	isIncludeRoot: true

        	# Whehter to follow symbol links or not.
        	isFollowLink: true

        	# Iterate children first, then parent folder.
        	isReverse: false

        	# When isReverse is false, it will be the previous iter resolve value.
        	val: any

        	# If it return false, sub-entries won't be searched.
        	# When the `filter` option returns false, its children will
        	# still be itered. But when `searchFilter` returns false, children
        	# won't be itered by the iter.
        	searchFilter: (fileInfo) -> true

        	# If you want sort the names of each level, you can hack here.
        	# Such as `(names) -> names.sort()`.
        	handleNames: (names) -> names
        }
        ```
        The argument of `opts.iter`, `fileInfo` object has these properties:
        ```coffee
        {
        	path: String
        	name: String
        	baseDir: String
        	isDir: Boolean
        	children: [fileInfo]
        	stats: fs.Stats
        	val: Any
        }
        ```
        Assume we call the function: `nofs.eachDir('dir', { iter: (f) -> f })`,
        the resolved directory object array may look like:
        ```coffee
        {
        	path: 'some/dir/path'
        	name: 'path'
        	baseDir: 'some/dir'
        	isDir: true
        	val: 'test'
        	children: [
        		{
        			path: 'some/dir/path/a.txt', name: 'a.txt'
        			baseDir: 'dir', isDir: false, stats: { ... }
        		}
        		{ path: 'some/dir/path/b.txt', name: 'b.txt', ... }
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
        The `stats` is a native `fs.Stats` object.

    - **<u>return</u>**: { _Promise_ }

        Resolves a directory tree object.

    - **<u>example</u>**:

        ```coffee
        # Print all file and directory names, and the modification time.
        nofs.eachDir 'dir/path', {
        	iter: (obj, stats) ->
        		console.log obj.path, stats.mtime
        }

        # Print path name list.
        nofs.eachDir 'dir/path', { iter: (curr) -> curr }
        .then (tree) ->
        	console.log tree

        # Find all js files.
        nofs.eachDir 'dir/path', {
        	filter: '**/*.js'
        	iter: ({ path }) ->
        		console.log paths
        }

        # Find all js files.
        nofs.eachDir 'dir/path', {
        	filter: /\.js$/
         iter: ({ path }) ->
        		console.log paths
        }

        # Custom filter.
        nofs.eachDir 'dir/path', {
        	filter: ({ path, stats }) ->
        		path.slice(-1) != '/' and stats.size > 1000
        	iter: (path) ->
        		console.log path
        }
        ```

- ### **[fileExists](src/main.coffee?source#L650)**

    Check if a path exists, and if it is a file.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>return</u>**: { _Promise_ }

        Resolves a boolean value.

- ### **[glob](src/main.coffee?source#L704)**

    Get files by patterns.

    - **<u>param</u>**: `pattern` { _String | Array_ }

        The minimatch pattern.
        Patterns that starts with '!' in the array will be used
        to exclude paths.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDir-opts).
        But the `filter` property will be fixed with the pattern.
        Defaults:
        ```coffee
        {
        	all: false

        	# The minimatch option object.
        	pmatch: {}

        	# It will be called after each match. It can also return
        	# a promise.
        	iter: (fileInfo, list) -> list.push fileInfo.path
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        Resolves the list array.

    - **<u>example</u>**:

        ```coffee
        # Get all js files.
        nofs.glob(['**/*.js', '**/*.css']).then (paths) ->
        	console.log paths

        # Exclude some files. "a.js" will be ignored.
        nofs.glob(['**/*.js', '!**/a.js']).then (paths) ->
        	console.log paths

        # Custom the iterator. Append '/' to each directory path.
        nofs.glob '**/*.js', {
        	iter: (info, list) ->
        		list.push if info.isDir
        			info.path + '/'
        		else
        			info.path
        }
        .then (paths) ->
        	console.log paths
        ```

- ### **[mapDir](src/main.coffee?source#L813)**

    Map file from a directory to another recursively with a
    callback.

    - **<u>param</u>**: `from` { _String_ }

        The root directory to start with.

    - **<u>param</u>**: `to` { _String_ }

        This directory can be a non-exists path.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDir-opts). But `cwd` is
        fixed with the same as the `from` parameter. Defaults:
        ```coffee
        {
        	# It will be called with each path. The callback can return
        	# a `Promise` to keep the async sequence go on.
        	iter: (src, dest, fileInfo) -> Promise | Any

        	isIterFileOnly: true
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        Resolves a tree object.

    - **<u>example</u>**:

        ```coffee
        # Copy and add license header for each files
        # from a folder to another.
        nofs.mapDir 'from', 'to', {
        	iter: (src, dest) ->
        		nofs.readFile(src).then (buf) ->
        			buf += 'License MIT\n' + buf
        			nofs.outputFile dest, buf
        }
        ```

- ### **[mkdirs](src/main.coffee?source#L859)**

    Recursively create directory path, like `mkdir -p`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `mode` { _String_ }

        Defaults: `0o777 & ~process.umask()`

    - **<u>return</u>**: { _Promise_ }

- ### **[move](src/main.coffee?source#L902)**

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
        	isFollowLink: false
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        It will resolve a boolean value which indicates
        whether this action is taken between two partitions.

- ### **[outputFile](src/main.coffee?source#L969)**

    Almost the same as `writeFile`, except that if its parent
    directories do not exist, they will be created.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `data` { _String | Buffer_ }

    - **<u>param</u>**: `opts` { _String | Object_ }

        <a id="outputFile-opts"></a>
        Same with the [writeFile](#writeFile-opts).

    - **<u>return</u>**: { _Promise_ }

- ### **[outputJson](src/main.coffee?source#L1001)**

    Write a object to a file, if its parent directory doesn't
    exists, it will be created.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `obj` { _Any_ }

        The data object to save.

    - **<u>param</u>**: `opts` { _Object | String_ }

        Extends the options of [outputFile](#outputFile-opts).
        Defaults:
        ```coffee
        {
        	replacer: null
        	space: null
        }
        ```

    - **<u>return</u>**: { _Promise_ }

- ### **[path](src/main.coffee?source#L1028)**

    The path module nofs is using.
    It's the native [io.js](iojs.org) path lib.
    nofs will force all the path separators to `/`,
    such as `C:\a\b` will be transformed to `C:/a/b`.

    - **<u>type</u>**: { _Object_ }

- ### **[pmatch](src/main.coffee?source#L1043)**

    The `minimatch` lib. It has two extra methods:
    - `isPmatch(String | Object) -> Pmatch | undefined`
        It helps to detect if a string or an object is a minimatch.

    - `getPlainPath(Pmatch) -> String`
        Helps to get the plain root path of a pattern. Such as `src/js/*.js`
        will get `src/js`

    [Documentation](https://github.com/isaacs/minimatch)

    [Offline Documentation](?gotoDoc=minimatch/readme.md)

- ### **[Promise](src/main.coffee?source#L1049)**

    What promise this lib is using.

    - **<u>type</u>**: { _Bluebird_ }

- ### **[promisify](src/main.coffee?source#L1056)**

    A callback style to promise helper.
    It doesn't depends on Bluebird.

    - **<u>type</u>**: { _Function_ }

- ### **[readJson](src/main.coffee?source#L1069)**

    Read A Json file and parse it to a object.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object | String_ }

        Same with the native `nofs.readFile`.

    - **<u>return</u>**: { _Promise_ }

        Resolves a parsed object.

    - **<u>example</u>**:

        ```coffee
        nofs.readJson('a.json').then (obj) ->
        	console.log obj.name, obj.age
        ```

- ### **[reduceDir](src/main.coffee?source#L1109)**

    Walk through directory recursively with a iterator.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDir-opts),
        with some extra options:
        ```coffee
        {
        	iter: (prev, path, isDir, stats) -> Promise | Any

        	# The init value of the walk.
        	init: undefined

        	isIterFileOnly: true
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        Final resolved value.

    - **<u>example</u>**:

        ```coffee
        # Concat all files.
        nofs.reduceDir 'dir/path', {
        	init: ''
        	iter: (val, { path }) ->
        		nofs.readFile(path).then (str) ->
        			val += str + '\n'
        }
        .then (ret) ->
        	console.log ret
        ```

- ### **[remove](src/main.coffee?source#L1149)**

    Remove a file or directory peacefully, same with the `rm -rf`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of [eachDir](#eachDir-opts). But
        the `isReverse` is fixed with `true`. Defaults:
        ```coffee
        { isFollowLink: false }
        ```

    - **<u>return</u>**: { _Promise_ }

- ### **[touch](src/main.coffee?source#L1187)**

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

- ### **[watchPath](src/main.coffee?source#L1256)**

    <a id="writeFile-opts"></a>
    Watch a file. If the file changes, the handler will be invoked.
    You can change the polling interval by using `process.env.pollingWatch`.
    Use `process.env.watchPersistent = 'off'` to disable the persistent.
    Why not use `nofs.watch`? Because `nofs.watch` is unstable on some file
    systems, such as Samba or OSX.

    - **<u>param</u>**: `path` { _String_ }

        The file path

    - **<u>param</u>**: `opts` { _Object_ }

        Defaults:
        ```coffee
        {
        	handler: (path, curr, prev, isDeletion) ->

        	# Auto unwatch the file while file deletion.
        	autoUnwatch: true

        	persistent: process.env.watchPersistent != 'off'
        	interval: +process.env.pollingWatch or 300
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        It resolves the `StatWatcher` object:
        ```
        {
        	path
        	handler
        }
        ```

    - **<u>example</u>**:

        ```coffee
        process.env.watchPersistent = 'off'
        nofs.watchPath 'a.js', {
        	handler: (path, curr, prev, isDeletion) ->
        		if curr.mtime != prev.mtime
        			console.log path
        }
        .then (watcher) ->
        	nofs.unwatchFile watcher.path, watcher.handler
        ```

- ### **[watchFiles](src/main.coffee?source#L1286)**

    Watch files, when file changes, the handler will be invoked.
    It is build on the top of `nofs.watchPath`.

    - **<u>param</u>**: `patterns` { _Array_ }

        String array with minimatch syntax.
        Such as `['*/**.css', 'lib/**/*.js']`.

    - **<u>param</u>**: `opts` { _Object_ }

        Same as the `nofs.watchPath`.

    - **<u>return</u>**: { _Promise_ }

        It contains the wrapped watch listeners.

    - **<u>example</u>**:

        ```coffee
        nofs.watchFiles '*.js', (path, curr, prev, isDeletion) ->
        	console.log path
        ```

- ### **[watchDir](src/main.coffee?source#L1326)**

    Watch directory and all the files in it.
    It supports three types of change: create, modify, move, delete.
    By default, `move` event is disabled.
    It is build on the top of `nofs.watchPath`.

    - **<u>param</u>**: `root` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Defaults:
        ```coffee
        {
        	# If the "path" ends with '/' it's a directory, else a file.
        	handler: (type, path, oldPath) ->

        	patterns: '**' # minimatch, string or array

        	# Whether to watch POSIX hidden file.
        	all: false

        	# The minimatch options.
        	pmatch: {}

        	isEnableMoveEvent: false
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        Resolves a object that keys are paths,
        values are listeners.

    - **<u>example</u>**:

        ```coffee
        # Only current folder, and only watch js and css file.
        nofs.watchDir 'lib', {
        	pattern: '*.+(js|css)'
        	handler: (type, path) ->
        		console.log type, path
        }
        ```

- ### **[writeFile](src/main.coffee?source#L1415)**

    A `writeFile` shim for `< Node v0.10`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `data` { _String | Buffer_ }

    - **<u>param</u>**: `opts` { _String | Object_ }

    - **<u>return</u>**: { _Promise_ }



## `graceful-fs`

You can use `process.env.gracefulFs == 'off'` to disable it.

## Benckmark

[`nofs.copy` vs `ncp`](benchmark/ncp.coffee)

## Lisence

MIT


[nokit]: https://github.com/ysmood/nokit