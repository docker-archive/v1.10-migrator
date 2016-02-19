package main

import (
	"compress/gzip"
	"errors"
	"io"
	"os"

	"github.com/Sirupsen/logrus"
	"github.com/docker/distribution/digest"
	"github.com/docker/docker/layer"
	"github.com/vbatts/tar-split/tar/asm"
	"github.com/vbatts/tar-split/tar/storage"
)

type Mounter interface {
	Mount(id string) (string, func(), error)
	TarStream(id, parent string) (io.ReadCloser, error)
}

type checksums struct {
	driver Mounter
}

func (c *checksums) ChecksumForGraphID(id, parent, oldTarDataPath, newTarDataPath string) (diffID layer.DiffID, size int64, err error) {
	defer func() {
		if err != nil {
			logrus.Debugf("could not get checksum for %q with tar-split: %q. Attempting fallback.", id, err)
			diffID, size, err = c.checksumForGraphIDNoTarsplit(id, parent, newTarDataPath)
		}
	}()

	if oldTarDataPath == "" {
		err = errors.New("no tar-split file")
		return
	}

	tarDataFile, err := os.Open(oldTarDataPath)
	if err != nil {
		return
	}
	defer tarDataFile.Close()
	uncompressed, err := gzip.NewReader(tarDataFile)
	if err != nil {
		return
	}

	dgst := digest.Canonical.New()
	err = c.assembleTarTo(id, uncompressed, &size, dgst.Hash())
	if err != nil {
		return
	}

	diffID = layer.DiffID(dgst.Digest())
	os.RemoveAll(newTarDataPath)
	err = os.Link(oldTarDataPath, newTarDataPath)
	return
}

func (c *checksums) assembleTarTo(graphID string, metadata io.ReadCloser, size *int64, w io.Writer) error {
	defer metadata.Close()

	// get our relative path to the container
	fsPath, release, err := c.driver.Mount(graphID)
	if err != nil {
		return err
	}
	if release != nil {
		defer release()
	}

	metaUnpacker := storage.NewJSONUnpacker(metadata)
	upackerCounter := &unpackSizeCounter{metaUnpacker, size}
	fileGetter := storage.NewPathFileGetter(fsPath)
	logrus.Debugf("Assembling tar data for %s from %s", graphID, fsPath)
	return asm.WriteOutputTarStream(fileGetter, upackerCounter, w)
}

func (c *checksums) checksumForGraphIDNoTarsplit(id, parent, newTarDataPath string) (diffID layer.DiffID, size int64, err error) {
	rawarchive, err := c.driver.TarStream(id, parent)
	if err != nil {
		return
	}
	defer rawarchive.Close()

	f, err := os.Create(newTarDataPath)
	if err != nil {
		return
	}
	defer f.Close()
	mfz := gzip.NewWriter(f)
	defer mfz.Close()
	metaPacker := storage.NewJSONPacker(mfz)

	packerCounter := &packSizeCounter{metaPacker, &size}

	archive, err := asm.NewInputTarStream(rawarchive, packerCounter, nil)
	if err != nil {
		return
	}
	dgst, err := digest.FromReader(archive)
	if err != nil {
		return
	}
	diffID = layer.DiffID(dgst)
	return
}

type unpackSizeCounter struct {
	unpacker storage.Unpacker
	size     *int64
}

func (u *unpackSizeCounter) Next() (*storage.Entry, error) {
	e, err := u.unpacker.Next()
	if err == nil && u.size != nil {
		*u.size += e.Size
	}
	return e, err
}

type packSizeCounter struct {
	packer storage.Packer
	size   *int64
}

func (p *packSizeCounter) AddEntry(e storage.Entry) (int, error) {
	n, err := p.packer.AddEntry(e)
	if err == nil && p.size != nil {
		*p.size += e.Size
	}
	return n, err
}
