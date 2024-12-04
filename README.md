# manage-shebangs
Manage shebangs for scripts.

The script can be called with the following options:
```
manage_shebang.sh:
-f file   -- the file you want to modify
-p string -- a path or prefix for your shebang (this can be something like /usr/bin, or even /usr/bin/env)
-e string -- the executable you want in the shebang
-i string -- ignore any files containing this string in the shebang
-v        -- verbose
-s        -- skip making '.orig' backups
-h        -- print a help message
```
Example commands: `manage_shebang.sh -f my_file.py -p /usr/bin/ -e my_wrapper`, which sets my_file.py's shebang to `#!/usr/bin/my_wrapper`


This is particularly useful when used with the find command:

`find . -name "*.py" -type f -exec ./manage_shebang.sh -f {} -e my_wrapper -v impala` - this will change all .py files that have a shebang with `#!/usr/bin/env my_wrapper` except for files that have `impala` in their existing shebang. This is useful for projects that already point to their own specific version of python.
