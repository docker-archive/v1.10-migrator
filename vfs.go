package main

import (
	"io"
	"os"
	"path/filepath"

	"github.com/docker/docker/pkg/archive"
)

type vfs struct {
	root string
}

func NewVfsChecksums(root string, opts []string) Mounter {
	return &vfs{root}
}

func (c *vfs) Mount(id string) (string, func(), error) {
	path := filepath.Join(c.root, "dir", id)
	if _, err := os.Lstat(path); err != nil {
		return "", nil, err
	}
	return path, nil, nil
}

func (c *vfs) TarStream(id, parent string) (io.ReadCloser, error) {
	mainPath, _, err := c.Mount(id)
	if err != nil {
		return nil, err
	}

	if parent == "" {
		return archive.Tar(mainPath, archive.Uncompressed)
	}

	parentPath, _, err := c.Mount(parent)
	if err != nil {
		return nil, err
	}
	return Diff(mainPath, parentPath)
}
