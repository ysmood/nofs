# [nofs](https://github.com/ysmood/nofs)

## Overview

`nofs` extends Node's native `fs` module with some useful methods. It tries
to make your functional programming experience better.

[![NPM version](https://badge.fury.io/js/nofs.svg)](http://badge.fury.io/js/nofs) [![Build Status](https://travis-ci.org/ysmood/nofs.svg)](https://travis-ci.org/ysmood/nofs) [![Build status](https://ci.appveyor.com/api/projects/status/11ddy1j4wofdhal7?svg=true)](https://ci.appveyor.com/project/ysmood/nofs)
 [![Deps Up to Date](https://david-dm.org/ysmood/nofs.svg?style=flat)](https://david-dm.org/ysmood/nofs)

## Features

- Introduce `map` and `reduce` to folders.
- Recursive `glob`, `move`, `copy`, `remove`, etc.
- **Promise** by default.
- Unified API. Support **Promise**, **Sync** and **Callback** paradigms.

## Install

```shell
npm install nofs
```

## API Convention

### Unix Path Separator

When the system is Windows and `process.env.force_unix_sep != 'off'`, nofs  will force all the path separator to `/`, such as `C:\a\b` will be transformed to `C:/a/b`.

### Promise, Sync and Callback

Any function that has a `Sync` version will has a promise version that ends with `P`.
For example the `fs.remove` will have `fs.removeSync` for sync IO, and `fs.removeP` for Promise.

### `eachDir`

It is the core function for directory manipulation. Other abstract functions
like `mapDir`, `reduceDir`, `glob` are built on top of it. You can play
with it if you don't like other functions.

### `nofs` vs Node Native `fs`

`nofs` only extends the native module, no pollution will be found. You can
still call `nofs.readFile` as easy as pie.

### Inheritance of Options

A Function's options may inherit other function's, especially the functions it calls internally. Such as the `glob` extends the `eachDir`'s
option, therefore `glob` also has a `filter` option.

## Quick Start

```coffee
# You can replace "require('fs')" with "require('nofs')"
fs = require 'nofs'

# Callback
fs.outputFile 'x.txt', 'test', (err) ->
    console.log 'done'

# Sync
fs.readFileSync 'x.txt'
fs.copySync 'dir/a', 'dir/b'

# Promise
fs.mkdirsP 'deep/dir/path'
.then ->
    fs.outputFileP 'a.txt', 'hello world'
.then ->
    fs.moveP 'a.txt', 'b.txt'
.then ->
    fs.copyP 'b.txt', 'c.js'
.then ->
    # Get all txt files.
    fs.globP 'deep/**'
.then (list) ->
    console.log list
.then ->
    # Remove only js files.
    fs.removeP 'deep', { filter: '**/*.js' }

# Concat all css files.
fs.reduceDirP 'dir/path', {
    init: '/* Concated by nofs */\n'
    filter: '**/*.css'
}, (sum, { path }) ->
    fs.readFileP(path).then (str) ->
        sum += str + '\n'
.then (concated) ->
    console.log concated

# Compile files from on place to another.
fs.mapDirP 'from', 'to', (src, dest) ->
    fs.readFileP(src, 'utf8').then (str) ->
        compiled = '/* Compiled by nofs */\n' + str
        fs.outputFileP dest, compiled
```

## Changelog

Goto [changelog](doc/changelog.md)

## API

__No native `fs` funtion will be listed.__

- #### **[Overview](src/main.coffee?source#L5)**

    I hate to reinvent the wheel. But to purely use promise, I don't
    have many choices.

- #### **[Promise](src/main.coffee?source#L16)**

    Here I use [Bluebird][Bluebird] only as an ES6 shim for Promise.
    No APIs other than ES6 spec will be used. In the
    future it will be removed.
    [Bluebird]: https://github.com/petkaantonov/bluebird

- #### **[copyDirP](src/main.coffee?source#L51)**

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

- #### **[copyDirSync](src/main.coffee?source#L75)**

    See `copyDirP`.

- #### **[copyFileP](src/main.coffee?source#L110)**

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

- #### **[copyFileSync](src/main.coffee?source#L153)**

    See `copyDirP`.

- #### **[copyP](src/main.coffee?source#L214)**

    Like `cp -r`.

    - **<u>param</u>**: `from` { _String_ }

        Source path.

    - **<u>param</u>**: `to` { _String_ }

        Destination path.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of `eachDir`.
        Defaults:
        ```coffee
        {
        	# Overwrite file if exists.
        	isForce: false
        	isFnFileOnly: false
        }
        ```

    - **<u>return</u>**: { _Promise_ }

- #### **[copySync](src/main.coffee?source#L247)**

    See `copyP`.

- #### **[dirExistsP](src/main.coffee?source#L280)**

    Check if a path exists, and if it is a directory.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>return</u>**: { _Promise_ }

        Resolves a boolean value.

- #### **[dirExistsSync](src/main.coffee?source#L290)**

    Check if a path exists, and if it is a directory.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>return</u>**: { _boolean_ }

- #### **[eachDirP](src/main.coffee?source#L394)**

    Walk through a path recursively with a callback. The callback
    can return a Promise to continue the sequence. The resolving order
    is also recursive, a directory path resolves after all its children
    are resolved.

    - **<u>param</u>**: `spath` { _String_ }

        The path may point to a directory or a file.

    - **<u>param</u>**: `opts` { _Object_ }

        Optional. Defaults:
        ```coffee
        {
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

        	# Such as force `C:\test\path` to `C:/test/path`.
        	# This option only works on Windows.
        	isForceUnixSep: isWin and process.env.force_unix_sep == 'off'
        }
        ```

    - **<u>param</u>**: `fn` { _Function_ }

        `(fileInfo) -> Promise | Any`.
        The `fileInfo` object has these properties: `{ path, isDir, children, stats }`.
        Assume the `fn` is `(f) -> f`, the directory object array may look like:
        ```coffee
        {
        	path: 'dir/path'
        	name: 'path'
        	isDir: true
        	val: 'test'
        	children: [
        		{ path: 'dir/path/a.txt', name: 'a.txt', isDir: false, stats: { ... } }
        		{ path: 'dir/path/b.txt', name: 'b.txt', isDir: false, stats: { ... } }
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

- #### **[eachDirSync](src/main.coffee?source#L490)**

    See `eachDirP`.

    - **<u>return</u>**: { _Object | Array_ }

        A tree data structure that
        represents the files recursively.

- #### **[fileExistsP](src/main.coffee?source#L591)**

    Check if a path exists, and if it is a file.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>return</u>**: { _Promise_ }

        Resolves a boolean value.

- #### **[fileExistsSync](src/main.coffee?source#L601)**

    Check if a path exists, and if it is a file.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>return</u>**: { _boolean_ }

- #### **[globP](src/main.coffee?source#L641)**

    Get files by patterns.

    - **<u>param</u>**: `pattern` { _String | Array_ }

        The minimatch pattern.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of `eachDir`.
        But the `filter` property will be fixed with the pattern.
        Defaults:
        ```coffee
        {
        	all: false

        	# The minimatch option object.
        	minimatch: {}
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
        nofs.globP('**/*.js').then (paths) ->
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

- #### **[globSync](src/main.coffee?source#L691)**

    See `globP`.

    - **<u>return</u>**: { _Array_ }

        The list array.

- #### **[mapDirP](src/main.coffee?source#L765)**

    Map file from a directory to another recursively with a
    callback.

    - **<u>param</u>**: `from` { _String_ }

        The root directory to start with.

    - **<u>param</u>**: `to` { _String_ }

        This directory can be a non-exists path.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of `eachDir`. But `cwd` is
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

- #### **[mapDirSync](src/main.coffee?source#L785)**

    See `mapDirP`.

    - **<u>return</u>**: { _Object | Array_ }

        A tree object.

- #### **[minimatch](src/main.coffee?source#L807)**

    The `minimatch` lib.
    [Documentation](https://github.com/isaacs/minimatch)
    [Offline Documentation](?gotoDoc=minimatch/readme.md)

    - **<u>type</u>**: { _Funtion_ }

- #### **[mkdirsP](src/main.coffee?source#L815)**

    Recursively create directory path, like `mkdir -p`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `mode` { _String_ }

        Defaults: `0o777 & ~process.umask()`

    - **<u>return</u>**: { _Promise_ }

- #### **[mkdirsSync](src/main.coffee?source#L838)**

    See `mkdirsP`.

- #### **[moveP](src/main.coffee?source#L861)**

    Moves a file or directory. Also works between partitions.
    Behaves like the Unix `mv`.

    - **<u>param</u>**: `from` { _String_ }

        Source path.

    - **<u>param</u>**: `to` { _String_ }

        Destination path.

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of `eachDir`.
        Defaults:
        ```coffee
        {
        	isForce: false
        }
        ```

    - **<u>return</u>**: { _Promise_ }

        It will resolve a boolean value which indicates
        whether this action is taken between two partitions.

- #### **[moveSync](src/main.coffee?source#L893)**

    See `moveP`.

- #### **[outputFileP](src/main.coffee?source#L929)**

    Almost the same as `writeFile`, except that if its parent
    directories do not exist, they will be created.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `data` { _String | Buffer_ }

    - **<u>param</u>**: `opts` { _String | Object_ }

        Same with the `nofs.writeFile`.

    - **<u>return</u>**: { _Promise_ }

- #### **[outputFileSync](src/main.coffee?source#L941)**

    See `outputFileP`.

- #### **[outputJsonP](src/main.coffee?source#L964)**

    Write a object to a file, if its parent directory doesn't
    exists, it will be created.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `obj` { _Any_ }

        The data object to save.

    - **<u>param</u>**: `opts` { _Object | String_ }

        Extends the options of `outputFileP`.
        Defaults:
        ```coffee
        {
        	replacer: null
        	space: null
        }
        ```

    - **<u>return</u>**: { _Promise_ }

- #### **[outputJsonSync](src/main.coffee?source#L978)**

    See `outputJSONP`.

- #### **[readJsonP](src/main.coffee?source#L996)**

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

- #### **[readJsonSync](src/main.coffee?source#L1007)**

    See `readJSONP`.

    - **<u>return</u>**: { _Any_ }

        The parsed object.

- #### **[reduceDirP](src/main.coffee?source#L1036)**

    Walk through directory recursively with a callback.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of `eachDir`,
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

- #### **[reduceDirSync](src/main.coffee?source#L1059)**

    See `reduceDirP`

    - **<u>return</u>**: { _Any_ }

        Final value.

- #### **[removeP](src/main.coffee?source#L1082)**

    Remove a file or directory peacefully, same with the `rm -rf`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `opts` { _Object_ }

        Extends the options of `eachDir`. But
        the `isReverse` is fixed with `true`.

    - **<u>return</u>**: { _Promise_ }

- #### **[removeSync](src/main.coffee?source#L1097)**

    See `removeP`.

- #### **[touchP](src/main.coffee?source#L1124)**

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

- #### **[touchSync](src/main.coffee?source#L1143)**

    See `touchP`.

    - **<u>return</u>**: { _Boolean_ }

        Whether a new file is created or not.

- #### **[watchFileP](src/main.coffee?source#L1182)**

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

- #### **[watchFilesP](src/main.coffee?source#L1213)**

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

- #### **[watchDirP](src/main.coffee?source#L1254)**

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
        	minimatch: {}

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
        nofs.watchDir {
        	dir: 'lib'
        	pattern: '*.+(js|css)'
        	handler: (type, path) ->
        		console.log type
        		console.log path
        }
        ```

- #### **[writeFileP](src/main.coffee?source#L1339)**

    A `writeFile` shim for `< Node v0.10`.

    - **<u>param</u>**: `path` { _String_ }

    - **<u>param</u>**: `data` { _String | Buffer_ }

    - **<u>param</u>**: `opts` { _String | Object_ }

    - **<u>return</u>**: { _Promise_ }

- #### **[writeFileSync](src/main.coffee?source#L1364)**

    See `writeFileP`



## Function Alias

For some naming convention reasons, `nofs` also uses some common alias for fucntions. See [src/alias.coffee](src/alias.coffee).

## Benckmark

[`nofs.copy` vs `ncp`](benchmark/ncp.coffee)

## Lisence

MIT