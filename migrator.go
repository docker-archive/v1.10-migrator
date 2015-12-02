package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/Sirupsen/logrus"
	"github.com/docker/docker/image"

	migrate "github.com/docker/docker/migrate/v1"
)

const autoDriver = "auto"

type mounterFunc func(string) Mounter

var drivers = map[string]mounterFunc{
	"aufs":         NewAufsChecksums,
	"overlay":      NewOverlayChecksums,
	"devicemapper": NewDevicemapperChecksums,
}

func main() {
	root := flag.String("g", "/var/lib/docker", "Docker root dir")
	driver := flag.String("s", autoDriver, "Storage driver to migrate")

	flag.Parse()
	logrus.SetLevel(logrus.DebugLevel)

	driverName, err := validateGraphDir(*root, *driver)
	if err != nil {
		logrus.Fatal(err)
	}
	mounter := drivers[driverName](filepath.Join(*root, driverName))
	migrate.CalculateLayerChecksums(*root, &checksums{mounter}, make(map[string]image.ID))

}

func validateGraphDir(root, driver string) (string, error) {
	_, err := os.Stat(root)
	if err != nil {
		return "", err
	}
	if driver == autoDriver {
		driver, err = findDriver(root)
		if err != nil {
			return "", err
		}
	}

	if _, ok := drivers[driver]; !ok {
		return "", fmt.Errorf("unknown storage driver %s", driver)
	}

	_, err = os.Stat(filepath.Join(root, driver))
	if err != nil {
		return "", err
	}

	return driver, nil
}

func findDriver(root string) (string, error) {
	var found []string
	for name := range drivers {
		if _, err := os.Stat(filepath.Join(root, name)); err == nil {
			found = append(found, name)
		}
	}
	if len(found) == 0 {
		return "", fmt.Errorf("no storage driver directory was found at %s", root)
	}
	if len(found) > 1 {
		return "", fmt.Errorf("multiple storage drivers found at %s, please specify one with \"-d\" option", root)
	}
	return found[0], nil
}
