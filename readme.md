# nofs

## Overview

Any function that has a `Sync` version will has a promise version that ends with `P`,
for example `fs.readFileSync` will have a `fs.readFileP`.

[![NPM version](https://badge.fury.io/js/nofs.svg)](http://badge.fury.io/js/nofs) [![Build Status](https://travis-ci.org/ysmood/nofs.svg)](https://travis-ci.org/ysmood/nofs) [![Build status](https://ci.appveyor.com/api/projects/status/11ddy1j4wofdhal7?svg=true)](https://ci.appveyor.com/project/ysmood/nofs)
 [![Deps Up to Date](https://david-dm.org/ysmood/nofs.svg?style=flat)](https://david-dm.org/ysmood/nofs)

## Install

```shell
npm install nofs
```

## Quick Start

```coffee
fs = require 'nofs'

# Callback
fs.outputFile 'x.txt', 'test', (err) ->
    console.log 'done'

# Sync
fs.outputFileSync 'x.txt', 'test'

# Promise
fs.mkdirsP 'deep/dir/path'
.then ->
    fs.outputFileP 'a.txt', 'hello world'
.then ->
    fs.moveP 'a.txt', 'b.txt'
.then ->
    fs.copyP 'b.txt', 'c.js'
.then ->
    # Get all folders.
    fs.readdirsP 'deep', { filter: /\/$/ }
.then (list) ->
    console.log list
.then ->
    fs.removeP 'deep'
```

## Changelog

Goto [changelog](doc/changelog.md)

## API

### nofs

- #### <a href="lib/main.coffee?source#L5" target="_blank"><b>Overview</b></a>

  I hate to reinvent the wheel. But to purely use promise, I don't
  have many choices.

- #### <a href="lib/main.coffee?source#L14" target="_blank"><b>Promise</b></a>

  Here I use Bluebird only as an ES6 shim for Promise.
  No APIs other than ES6 spec will be used.

- #### <a href="lib/main.coffee?source#L45" target="_blank"><b>copyDirP</b></a>

  Copy a directory.

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

- #### <a href="lib/main.coffee?source#L80" target="_blank"><b>copyFileP</b></a>

  Copy a file.

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

- #### <a href="lib/main.coffee?source#L131" target="_blank"><b>copyP</b></a>

  Like `cp -r`.

  - **<u>param</u>**: `from` { _String_ }

    Source path.

  - **<u>param</u>**: `to` { _String_ }

    Destination path.

  - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	# Overwrite file if exists.
    	isForce: false
    
    	# Same with the `readdirs`'s
    	filter: (path) -> true
    }
    ```

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/main.coffee?source#L169" target="_blank"><b>dirExistsP</b></a>

  Check if a path exists, and if it is a directory.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _Promise_ }

    Resolves a boolean value.

- #### <a href="lib/main.coffee?source#L179" target="_blank"><b>dirExistsSync</b></a>

  Check if a path exists, and if it is a directory.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _boolean_ }

- #### <a href="lib/main.coffee?source#L209" target="_blank"><b>eachDirP</b></a>

  Walk through directory recursively with a callback.

  - **<u>param</u>**: `root` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    It extend the options of `readdirs`,
    with some extra options:
    ```coffee
    {
    	# Walk children files first.
    	isReverse: false
    }
    ```

  - **<u>param</u>**: `fn` { _Function_ }

    `(path, stats) -> Promise`

  - **<u>return</u>**:  { _Promise_ }

    Final resolved value.

  - **<u>example</u>**:

    ```coffee
    # Print path name list.
    nofs.eachDirP 'dir/path', (path) ->
    	console.log path
    
    # Print path name list.
    nofs.eachDirP 'dir/path', { isCacheStats: true }, (path, stats) ->
    	console.log path, stats.isFile()
    ```

- #### <a href="lib/main.coffee?source#L229" target="_blank"><b>fileExistsP</b></a>

  Check if a path exists, and if it is a file.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _Promise_ }

    Resolves a boolean value.

- #### <a href="lib/main.coffee?source#L239" target="_blank"><b>fileExistsSync</b></a>

  Check if a path exists, and if it is a file.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _boolean_ }

- #### <a href="lib/main.coffee?source#L251" target="_blank"><b>mkdirsP</b></a>

  Recursively create directory path, like `mkdir -p`.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `mode` { _String_ }

    Defauls: `0o777 & ~process.umask()`

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/main.coffee?source#L277" target="_blank"><b>moveP</b></a>

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
    	filter: (path) -> true
    }
    ```

  - **<u>return</u>**:  { _Promise_ }

    It will resolve a boolean value which indicates
    whether this action is taken between two partitions.

- #### <a href="lib/main.coffee?source#L340" target="_blank"><b>outputFileP</b></a>

  Almost the same as `writeFile`, except that if its parent
  directories do not exist, they will be created.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `data` { _String | Buffer_ }

  - **<u>param</u>**: `opts` { _String | Object_ }

    Same with the `fs.writeFile`.
    > Remark: For `<= Node v0.8` the `opts` can also be an object.

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/main.coffee?source#L408" target="_blank"><b>readdirsP</b></a>

  Read directory recursively.

  - **<u>param</u>**: `root` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	# To filter paths.
    	filter: (path, stats) -> true
    
    	isCacheStats: false
    
    	# The current working directory to search.
    	cwd: ''
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
    nofs.readdirsP 'dir/path'
    .then (paths) ->
    	console.log paths # output => ['dir/path/a', 'dir/path/b/c']
    
    # Same with the above, but cwd is changed.
    nofs.readdirsP 'path', { cwd: 'dir' }
    .then (paths) ->
    	console.log paths # output => ['path/a', 'path/b/c']
    
    # CacheStats
    nofs.readdirsP 'dir/path', { isCacheStats: true }
    .then (paths) ->
    	console.log paths.statsCache['path/a']
    
    # Find all js files.
    nofs.readdirsP 'dir/path', { filter: /.+\.js$/ }
    .then (paths) -> console.log paths
    
    # Custom handler
    nofs.readdirsP 'dir/path', {
    	filter: (path, stats) ->
    		path.indexOf('a') > -1 and stats.isFile()
    }
    .then (paths) -> console.log paths
    ```

- #### <a href="lib/main.coffee?source#L463" target="_blank"><b>removeP</b></a>

  Remove a file or directory peacefully, same with the `rm -rf`.

  - **<u>param</u>**: `root` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	# Same with the `readdirs`'s.
    	filter: (path) -> true
    }
    ```

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/main.coffee?source#L495" target="_blank"><b>touchP</b></a>

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

- #### <a href="lib/main.coffee?source#L533" target="_blank"><b>mapDirP</b></a>

  Map file from a directory to another recursively with a
  callback.

  - **<u>param</u>**: `from` { _String_ }

    The root directory to start with.

  - **<u>param</u>**: `to` { _String_ }

    This directory can be a non-exists path.

  - **<u>param</u>**: `opts` { _Object_ }

    Same with the `readdirs`. But `cwd` is
    fixed with the same as the `from` parameter.

  - **<u>param</u>**: `fn` { _Function_ }

    The callback will be called
    with each path. The callback can return a `Promise` to
    keep the async sequence go on.

  - **<u>return</u>**:  { _Promise_ }

  - **<u>example</u>**:

    ```coffee
    nofs.mapDirP(
    	'from'
    	'to'
    	{ isCacheStats: true }
    	(src, dest, stats) ->
    		return if stats.isDirectory()
    		buf = nofs.readFileP src
    		buf += 'some contents'
    		nofs.writeFileP dest, buf
    )
    ```

- #### <a href="lib/main.coffee?source#L570" target="_blank"><b>reduceDirP</b></a>

  Walk through directory recursively with a callback.

  - **<u>param</u>**: `root` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    It extend the options of `readdirs`,
    with some extra options:
    ```coffee
    {
    	# Walk children files first.
    	isReverse: false
    
    	# The init value of the walk.
    	init: undefined
    }
    ```

  - **<u>param</u>**: `fn` { _Function_ }

    `(preVal, path, stats) -> Promise`

  - **<u>return</u>**:  { _Promise_ }

    Final resolved value.

  - **<u>example</u>**:

    ```coffee
    # Print path name list.
    nofs.reduceDirP 'dir/path', { init: '' }, (val, path) ->
    	val += path + '\n'
    .then (ret) ->
    	console.log ret
    ```

- #### <a href="lib/main.coffee?source#L599" target="_blank"><b>writeFileP</b></a>

  A `writeFile` shim for `<= Node v0.8`.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `data` { _String | Buffer_ }

  - **<u>param</u>**: `opts` { _String | Object_ }

  - **<u>return</u>**:  { _Promise_ }



## Lisence

MIT