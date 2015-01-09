# [nofs](https://github.com/ysmood/nofs)

## Overview

`nofs` extends Node's native `fs` module with some useful methods.

[![NPM version](https://badge.fury.io/js/nofs.svg)](http://badge.fury.io/js/nofs) [![Build Status](https://travis-ci.org/ysmood/nofs.svg)](https://travis-ci.org/ysmood/nofs) [![Build status](https://ci.appveyor.com/api/projects/status/11ddy1j4wofdhal7?svg=true)](https://ci.appveyor.com/project/ysmood/nofs)
 [![Deps Up to Date](https://david-dm.org/ysmood/nofs.svg?style=flat)](https://david-dm.org/ysmood/nofs)

## Features

- Super light weight, no dependency.
- **Promise** by default.
- Unified API. Support **Promise**, **Sync** and **Callback** paradigms.

## Install

```shell
npm install nofs
```

## API Convention

### Promise, Sync and Callback

Any function that has a `Sync` version will has a promise version that ends with `P`.
For example the `fs.remove` will have `fs.removeSync` for sync IO, and `fs.removeP` for Promise.

### `eachDir`

It is the core function for directory manipulation. Other abstract functions
like `mapDir`, `reduceDir`, `readDirs` are built on top of it. You can play
with it if you don't like other functions.

### `nofs` vs Node Native `fs`

`nofs` only extends the native module, no pollution will be found. You can
still call `nofs.readFile` as easy as pie.

### Inheritance of Options

A Function's options may inherit other function's, especially the functions it calls internally. Such as the `readDirs` extends the `eachDir`'s
option, therefore `readDirs` also has a `filter` option.

## Quick Start

```coffee
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
    fs.readDirsP 'deep', { filter: /\.txt$/ }
.then (list) ->
    console.log list
.then ->
    fs.removeP 'deep'
```

## Changelog

Goto [changelog](doc/changelog.md)

## API

__No native `fs` funtion will be listed.__

### nofs

- #### <a href="src/main.coffee?source#L5" target="_blank"><b>Overview</b></a>

  I hate to reinvent the wheel. But to purely use promise, I don't
  have many choices.

- #### <a href="src/main.coffee?source#L16" target="_blank"><b>Promise</b></a>

  Here I use [Bluebird][Bluebird] only as an ES6 shim for Promise.
  No APIs other than ES6 spec will be used. In the
  future it will be removed.
  [Bluebird]: https://github.com/petkaantonov/bluebird

- #### <a href="src/main.coffee?source#L47" target="_blank"><b>copyDirP</b></a>

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

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="src/main.coffee?source#L106" target="_blank"><b>copyFileP</b></a>

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

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="src/main.coffee?source#L194" target="_blank"><b>copyP</b></a>

  Like `cp -r`.

  - **<u>param</u>**: `from` { _String_ }

    Source path.

  - **<u>param</u>**: `to` { _String_ }

    Destination path.

  - **<u>param</u>**: `opts` { _Object_ }

    Extends the options of `eachDir`.
    But the `isCacheStats` is fixed with `true`.
    Defaults:
    ```coffee
    {
    	# Overwrite file if exists.
    	isForce: false
    }
    ```

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="src/main.coffee?source#L256" target="_blank"><b>dirExistsP</b></a>

  Check if a path exists, and if it is a directory.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _Promise_ }

    Resolves a boolean value.

- #### <a href="src/main.coffee?source#L266" target="_blank"><b>dirExistsSync</b></a>

  Check if a path exists, and if it is a directory.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _boolean_ }

- #### <a href="src/main.coffee?source#L340" target="_blank"><b>eachDirP</b></a>

  Walk through a path recursively with a callback. The callback
  can return a Promise to continue the sequence. The resolving order
  is also recursive, a directory path resolves after all its children
  are resolved.

  - **<u>param</u>**: `path` { _String_ }

    The path may point to a directory or a file.

  - **<u>param</u>**: `opts` { _Object_ }

    Optional. Defaults:
    ```coffee
    {
    	# The current working directory to search.
    	cwd: ''
    
    	# Whether to include the root directory or not.
    	isIncludeRoot: true
    
    	# Whehter to follow symbol links or not.
    	isFollowLink: true
    
    	# Iterate children first, then parent folder.
    	isReverse: false
    }
    ```

  - **<u>param</u>**: `fn` { _Function_ }

    `(fileInfo) -> Promise | Any`.
    The `fileInfo` object has these properties: `{ path, isDir, children, stats }`.
    If the `fn` is `(c) -> c`, the directory object array may look like:
    ```coffee
    {
    	path: 'dir/path'
    	isDir: true
    	val: 'test'
    	children: [
    		{ path: 'dir/path/a.txt', isDir: false, stats: { ... } }
    		{ path: 'dir/path/b.txt', isDir: false, stats: { ... } }
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

  - **<u>return</u>**:  { _Promise_ }

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
    nofs.eachDirP 'dir/path', { filter: /\.js$/ }, ({ path }) ->
    	console.log paths
    
    # Custom filter
    nofs.eachDirP 'dir/path', {
    	filter: ({ path, stats }) ->
    		path.slice(-1) != '/' and stats.size > 1000
    }, (path) ->
    	console.log path
    ```

- #### <a href="src/main.coffee?source#L456" target="_blank"><b>fileExistsP</b></a>

  Check if a path exists, and if it is a file.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _Promise_ }

    Resolves a boolean value.

- #### <a href="src/main.coffee?source#L466" target="_blank"><b>fileExistsSync</b></a>

  Check if a path exists, and if it is a file.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _boolean_ }

- #### <a href="src/main.coffee?source#L478" target="_blank"><b>mkdirsP</b></a>

  Recursively create directory path, like `mkdir -p`.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `mode` { _String_ }

    Defaults: `0o777 & ~process.umask()`

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="src/main.coffee?source#L513" target="_blank"><b>moveP</b></a>

  Moves a file or directory. Also works between partitions.
  Behaves like the Unix `mv`.

  - **<u>param</u>**: `from` { _String_ }

    Source path.

  - **<u>param</u>**: `to` { _String_ }

    Destination path.

  - **<u>param</u>**: `opts` { _Object_ }

    Extends the options of `eachDir`.
    But the `isCacheStats` is fixed with `true`.
    Defaults:
    ```coffee
    {
    	isForce: false
    }
    ```

  - **<u>return</u>**:  { _Promise_ }

    It will resolve a boolean value which indicates
    whether this action is taken between two partitions.

- #### <a href="src/main.coffee?source#L585" target="_blank"><b>outputFileP</b></a>

  Almost the same as `writeFile`, except that if its parent
  directories do not exist, they will be created.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `data` { _String | Buffer_ }

  - **<u>param</u>**: `opts` { _String | Object_ }

    Same with the `fs.writeFile`.

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="src/main.coffee?source#L649" target="_blank"><b>readDirsP</b></a>

  Read directory recursively.

  - **<u>param</u>**: `root` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    Extends the options of `eachDir`. Defaults:
    ```coffee
    {
    	# To filter paths. It can also be a RegExp.
    	filter: -> true
    
    	# Don't include the root directory.
    	isIncludeRoot: false
    
    	isCacheStats: false
    }
    ```
    If `isCacheStats` is set true, the return list array
    will have an extra property `statsCache`, it is something like:
    ```coffee
    {
    	'path/to/entity': {
    		dev: 16777220
    		mode: 33188
    		...
    	}
    }
    ```
    The key is the entity path, the value is the `fs.Stats` object.

  - **<u>return</u>**:  { _Promise_ }

    Resolves an path array. Every directory path will ends
    with `/` (Unix) or `\` (Windows).

  - **<u>example</u>**:

    ```coffee
    # Basic
    nofs.readDirsP 'dir/path'
    .then (paths) ->
    	console.log paths # output => ['dir/path/a', 'dir/path/b/c']
    
    # Same with the above, but cwd is changed.
    nofs.readDirsP 'path', { cwd: 'dir' }
    .then (paths) ->
    	console.log paths # output => ['path/a', 'path/b/c']
    
    # CacheStats
    nofs.readDirsP 'dir/path', { isCacheStats: true }
    .then (paths) ->
    	console.log paths.statsCache['path/a']
    ```

- #### <a href="src/main.coffee?source#L702" target="_blank"><b>removeP</b></a>

  Remove a file or directory peacefully, same with the `rm -rf`.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    Extends the options of `eachDir`. But
    the `isReverse` is fixed with `true`.

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="src/main.coffee?source#L749" target="_blank"><b>touchP</b></a>

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

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="src/main.coffee?source#L801" target="_blank"><b>mapDirP</b></a>

  Map file from a directory to another recursively with a
  callback.

  - **<u>param</u>**: `from` { _String_ }

    The root directory to start with.

  - **<u>param</u>**: `to` { _String_ }

    This directory can be a non-exists path.

  - **<u>param</u>**: `opts` { _Object_ }

    Extends the options of `eachDir`. But `cwd` is
    fixed with the same as the `from` parameter.

  - **<u>param</u>**: `fn` { _Function_ }

    `(src, dest, fileInfo) -> Promise | Any` The callback
    will be called with each path. The callback can return a `Promise` to
    keep the async sequence go on.

  - **<u>return</u>**:  { _Promise_ }

  - **<u>example</u>**:

    ```coffee
    # Copy and add license header for each files
    # from a folder to another.
    nofs.mapDirP(
    	'from'
    	'to'
    	{ isCacheStats: true }
    	(src, dest, fileInfo) ->
    		return if fileInfo.isDir
    		nofs.readFileP(src).then (buf) ->
    			buf += 'License MIT\n' + buf
    			nofs.writeFileP dest, buf
    )
    ```

- #### <a href="src/main.coffee?source#L849" target="_blank"><b>reduceDirP</b></a>

  Walk through directory recursively with a callback.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    Extends the options of `eachDir`,
    with some extra options:
    ```coffee
    {
    	# The init value of the walk.
    	init: undefined
    }
    ```

  - **<u>param</u>**: `fn` { _Function_ }

    `(prev, path, isDir, stats) -> Promise`

  - **<u>return</u>**:  { _Promise_ }

    Final resolved value.

  - **<u>example</u>**:

    ```coffee
    # Concat all files.
    nofs.reduceDirP 'dir/path', { init: '' }, (val, info) ->
    	return val if info.isDir
    	nofs.readFileP(info.path).then (str) ->
    		val += str + '\n'
    .then (ret) ->
    	console.log ret
    ```

- #### <a href="src/main.coffee?source#L883" target="_blank"><b>writeFileP</b></a>

  A `writeFile` shim for `< Node v0.10`.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `data` { _String | Buffer_ }

  - **<u>param</u>**: `opts` { _String | Object_ }

  - **<u>return</u>**:  { _Promise_ }



## Benckmark

[`nofs.copy` vs `ncp`](benchmark/ncp.coffee)

## Lisence

MIT