package main

import (
	"io"
	"os"
	"path/filepath"

	"github.com/docker/docker/pkg/archive"
)

type aufs struct {
	root string
}

func NewAufsChecksums(root string, opts []string) Mounter {
	return &aufs{root}
}

func (c *aufs) Mount(id string) (string, func(), error) {
	path := filepath.Join(c.root, "diff", id)
	if _, err := os.Lstat(path); err != nil {
		return "", nil, err
	}
	return path, nil, nil
}

func (c *aufs) TarStream(id, parent string) (io.ReadCloser, error) {
	path, _, err := c.Mount(id)
	if err != nil {
		return nil, err
	}

	return archive.TarWithOptions(path, &archive.TarOptions{
		Compression:     archive.Uncompressed,
		ExcludePatterns: []string{archive.WhiteoutMetaPrefix + "*", "!" + archive.WhiteoutOpaqueDir},
	})
}
