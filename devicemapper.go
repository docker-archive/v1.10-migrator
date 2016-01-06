package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"sync"

	"github.com/Sirupsen/logrus"
	"github.com/docker/docker/daemon/graphdriver/devmapper"
	"github.com/docker/docker/pkg/archive"
	"github.com/docker/docker/pkg/ioutils"
)

type mount struct {
	activity int
	path     string
}

type devicemapper struct {
	sync.Mutex
	mounts  map[string]*mount
	root    string
	devices *devmapper.DeviceSet
}

func NewDevicemapperChecksums(root string) Mounter {
	devices, err := devmapper.NewDeviceSet(root, false, nil, nil, nil)
	if err != nil {
		logrus.Errorf("Can't initialize device mapper: %q", err)
		os.Exit(1)
	}

	return &devicemapper{root: root, devices: devices, mounts: make(map[string]*mount)}
}

func (c *devicemapper) Mount(id string) (string, func(), error) {
	c.Lock()
	defer c.Unlock()

	mounts, ok := c.mounts[id]
	if !ok {
		tmpdir, err := ioutil.TempDir("", "migrate-devicemapper")
		if err != nil {
			return "", nil, err
		}
		mounts = &mount{0, tmpdir}
		c.mounts[id] = mounts
	}

	if mounts.activity == 0 {
		err := c.devices.MountDevice(id, mounts.path, "")
		if err != nil {
			return "", nil, fmt.Errorf("Can't create snap device: %v", err)
		}
	}
	mounts.activity++

	path := filepath.Join(mounts.path, "rootfs")
	// sometimes rootfs does not exist. return empty dir then
	if _, err := os.Lstat(path); err != nil {
		tmpdir, err := ioutil.TempDir("", "migrate-devicemapper")
		if err != nil {
			return "", nil, err
		}
		path = tmpdir
	}

	return path, func() {
		c.umount(id)
	}, nil
}

func (c *devicemapper) umount(id string) {
	c.Lock()
	defer c.Unlock()
	c.mounts[id].activity--
	if c.mounts[id].activity == 0 {
		err := c.devices.UnmountDevice(id, c.mounts[id].path)
		if err != nil {
			logrus.Errorf("Can't umount %s: %v", id, err)
		}
		os.RemoveAll(c.mounts[id].path)
		delete(c.mounts, id)
	}
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
