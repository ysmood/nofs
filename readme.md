# nofs

## Overview

Any function that has a `Sync` version will has a promise version that ends with `P`,
for example `fs.readFileSync` will have a `fs.readFileP`.

## Changelog

Goto [changelog](doc/changelog.md)

## API

### kit

- #### <a href="lib/main.coffee?source#L5" target="_blank"><b>Overview</b></a>

  I hate to reinvent the wheel. But to purely use promise, I don't
  have many choices.

- #### <a href="lib/main.coffee?source#L41" target="_blank"><b>copyP</b></a>

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
    	filter: undefined
    }
    ```

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/main.coffee?source#L93" target="_blank"><b>dirExistsP</b></a>

  Check if a path exists, and if it is a directory.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _Promise_ }

    Resolves a boolean value.

- #### <a href="lib/main.coffee?source#L103" target="_blank"><b>dirExistsSync</b></a>

  Check if a path exists, and if it is a directory.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _boolean_ }

- #### <a href="lib/main.coffee?source#L121" target="_blank"><b>fileExistsP</b></a>

  Check if a path exists, and if it is a file.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _Promise_ }

    Resolves a boolean value.

- #### <a href="lib/main.coffee?source#L131" target="_blank"><b>fileExistsSync</b></a>

  Check if a path exists, and if it is a file.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>return</u>**:  { _boolean_ }

- #### <a href="lib/main.coffee?source#L143" target="_blank"><b>mkdirsP</b></a>

  Recursively create directory path, like `mkdir -p`.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `mode` { _String_ }

    Defauls: `0o777`

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/main.coffee?source#L169" target="_blank"><b>moveP</b></a>

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
    	filter: undefined
    }
    ```

  - **<u>return</u>**:  { _Promise_ }

    It will resolve a boolean value which indicates
    whether this action is taken between two partitions.

- #### <a href="lib/main.coffee?source#L231" target="_blank"><b>outputFileP</b></a>

  Almost the same as `writeFile`, except that if its parent
  directory does not exist, it will be created.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `data` { _String | Buffer_ }

  - **<u>param</u>**: `opts` { _String | Object_ }

    Same with the `fs.writeFile`.
    > Remark: For `<= Node v0.8` the `opts` can also be an object.

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/main.coffee?source#L268" target="_blank"><b>readdirsP</b></a>

  Read directory recursively.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	# To filter paths.
    	filter: undefined
    	isCacheStats: false
    	cwd: '.'
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

- #### <a href="lib/main.coffee?source#L318" target="_blank"><b>removeP</b></a>

  Remove a file or directory peacefully, same with the `rm -rf`.

  - **<u>param</u>**: `root` { _String_ }

  - **<u>param</u>**: `opts` { _Object_ }

    Defaults:
    ```coffee
    {
    	# Same with the `readdirs`'s.
    	filter: undefined
    }
    ```

  - **<u>return</u>**:  { _Promise_ }

- #### <a href="lib/main.coffee?source#L351" target="_blank"><b>touchP</b></a>

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

- #### <a href="lib/main.coffee?source#L388" target="_blank"><b>mapdirP</b></a>

  Map file from a directory to another recursively with a
  callback.

  - **<u>param</u>**: `from` { _String_ }

    The root directory to start with.

  - **<u>param</u>**: `to` { _String_ }

    This directory can be a non-exists path.

  - **<u>param</u>**: `opts` { _Object_ }

    Same with the `readdirs`.

  - **<u>param</u>**: `fn` { _Function_ }

    The callback will be called
    with each path. The callback can return a `Promise` to
    keep the async sequence go on.

  - **<u>return</u>**:  { _Promise_ }

  - **<u>example</u>**:

    ```coffee
    nofs.mapdirP(
    	'from'
    	'to'
    	{ isCacheStats: true }
    	(src, dest, stats) ->
    		console.log stats.mode
    		buf = nofs.readFileP src
    		buf += 'some contents'
    		nofs.writeFile dest, buf
    )
    ```

- #### <a href="lib/main.coffee?source#L405" target="_blank"><b>writeFileP</b></a>

  A `writeFile` shim for `<= Node v0.8`.

  - **<u>param</u>**: `path` { _String_ }

  - **<u>param</u>**: `data` { _String | Buffer_ }

  - **<u>param</u>**: `opts` { _String | Object_ }

  - **<u>return</u>**:  { _Promise_ }



## Lisence

MIT