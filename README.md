# docker/v1.10-migrator

Starting from `v1.10` docker uses content addressable IDs for the images and layers instead of using generated ones. This tool calculates SHA256 checksums for docker layer content, so that they don't need to be recalculated when the daemon starts for the first time.

The migration usually runs on daemon startup but it can be quite slow(usually 100-200MB/s) and daemon will not be able to accept requests during that time. You can run this tool instead while the old daemon is still running and skip checksum calculation on startup.

## Usage

```
v1.10-migrator --help
Usage of v1.10-migrator:
  -g string
    	Docker root dir (default "/var/lib/docker")
  -s string
    	Storage driver to migrate (default "auto")
```

Supported storage drivers are `aufs`, `overlay`, `btrfs` and `devicemapper`. `auto` tries to automatically detect the driver from the root directory. `zfs` is currently not supported.

### Copyright and license

Copyright © 2016 Docker, Inc. All rights reserved, except as follows. Code
is released under the Apache 2.0 license. The README.md file, and files in the
"docs" folder are licensed under the Creative Commons Attribution 4.0
International License under the terms and conditions set forth in the file
"LICENSE.docs". You may obtain a duplicate copy of the same license, titled
CC-BY-SA-4.0, at http://creativecommons.org/licenses/by/4.0/.
