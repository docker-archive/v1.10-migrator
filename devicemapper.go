package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"syscall"

	"github.com/Sirupsen/logrus"
	"github.com/docker/docker/daemon/graphdriver/devmapper"
	"github.com/docker/docker/pkg/archive"
	"github.com/docker/docker/pkg/ioutils"
)

type devicemapper struct {
	root    string
	devices *devmapper.DeviceSet
}

func NewDevicemapperChecksums(root string) Mounter {
	devices, err := devmapper.NewDeviceSet(root, false, nil, nil, nil)
	if err != nil {
		logrus.Errorf("Can't initialize device mapper: %q", err)
		os.Exit(1)
	}

	return &devicemapper{root, devices}
}

func (c *devicemapper) Mount(id string) (string, func(), error) {
	tmpdir, err := ioutil.TempDir("", "migrate-devicemapper")
	if err != nil {
		return "", nil, err
	}

	err = c.devices.MountDevice(id, tmpdir, "")
	if err != nil {
		fmt.Println("Can't create snap device: ", err)
		os.Exit(1)
	}
	return filepath.Join(tmpdir, "rootfs"), func() {
		syscall.Unmount(tmpdir, 0)
		os.RemoveAll(tmpdir)
	}, nil
}

func (c *devicemapper) TarStream(id, parent string) (io.ReadCloser, error) {
	mainPath, releaseMain, err := c.Mount(id)
	if err != nil {
		return nil, err
	}

	if parent == "" {
		tar, err := archive.Tar(mainPath, archive.Uncompressed)
		if err != nil {
			return nil, err
		}
		return ioutils.NewReadCloserWrapper(tar, func() error {
			releaseMain()
			return tar.Close()
		}), nil
	}

	parentPath, releaseParent, err := c.Mount(parent)
	if err != nil {
		releaseMain()
		return nil, err
	}
	tar, err := Diff(mainPath, parentPath)
	if err != nil {
		releaseParent()
		releaseMain()
		return nil, err
	}
	return ioutils.NewReadCloserWrapper(tar, func() error {
		releaseParent()
		releaseMain()
		return tar.Close()
	}), nil
}
