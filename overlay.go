package main

import (
	"io"
	"os"
	"path/filepath"

	"github.com/docker/docker/pkg/archive"
)

type overlay struct {
	root string
}

func NewOverlayChecksums(root string, opts []string) Mounter {
	return &overlay{root}
}

func (c *overlay) Mount(id string) (string, func(), error) {
	path := filepath.Join(c.root, id, "root")
	if _, err := os.Lstat(path); err != nil {
		return "", nil, err
	}
	return path, nil, nil
}

func (c *overlay) TarStream(id, parent string) (io.ReadCloser, error) {
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

func Diff(mainPath, parentPath string) (arch io.ReadCloser, err error) {
	changes, err := archive.ChangesDirs(mainPath, parentPath)
	if err != nil {
		return nil, err
	}

	return archive.ExportChanges(mainPath, changes, nil, nil)
}
