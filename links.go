package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/docker/v1.10-migrator/graphdb"
)

func migrateLinks(root string) error {
	linkGraphDB := filepath.Join(root, "linkgraph.db")
	db, err := graphdb.NewSqliteConn(linkGraphDB)
	if err != nil {
		return fmt.Errorf("sqlite %s: %v", linkGraphDB, err)
	}
	defer db.Close()
	cDir := filepath.Join(root, "containers")
	cDb, err := newContainersDB(cDir, db)
	if err != nil {
		return fmt.Errorf("reading containers: %v", err)
	}

	if err := cDb.MigrateAll(); err != nil {
		return fmt.Errorf("migration: %v", err)
	}
	if err := cDb.Write(); err != nil {
		return fmt.Errorf("write hostconfig: %v", err)
	}
	return nil
}

type HostConfig map[string]interface{}

func (hs HostConfig) Name() (string, error) {
	iName, ok := hs["Name"]
	if !ok {
		return "", fmt.Errorf("Name field not found")
	}
	name, ok := iName.(string)
	if !ok {
		return "", fmt.Errorf("invalid Name type: %T", iName)
	}
	return name, nil
}

func (hs HostConfig) HasLinks() (bool, error) {
	iLs, ok := hs["Links"]
	if !ok {
		return false, nil
	}
	if iLs == nil {
		return false, nil
	}
	ls, ok := iLs.([]string)
	if !ok {
		return false, fmt.Errorf("invalid Links type: %T", iLs)
	}
	return ls != nil, nil
}

type Container struct {
	Name       string
	HostConfig HostConfig
}

type containersDB struct {
	cnts  map[string]*Container
	dir   string
	graph *graphdb.Database
}

func newContainersDB(dir string, graph *graphdb.Database) (*containersDB, error) {
	cLst, err := ioutil.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("read %s: %v", dir, err)
	}

	db := &containersDB{
		cnts:  make(map[string]*Container),
		dir:   dir,
		graph: graph,
	}

	for _, cDir := range cLst {
		if !cDir.IsDir() {
			continue
		}
		id := cDir.Name()
		cFile := filepath.Join(dir, id, "config.json")
		cnt, err := readConfig(cFile)
		if err != nil {
			return nil, fmt.Errorf("read config: %v", err)
		}
		hsFile := filepath.Join(dir, id, "hostconfig.json")
		hs, err := readHostConfig(hsFile)
		if err != nil {
			return nil, fmt.Errorf("read host config: %v", err)
		}
		cnt.HostConfig = hs
		db.cnts[id] = cnt
	}
	return db, nil
}

func (db *containersDB) Write() error {
	for id, cnt := range db.cnts {
		cFile := filepath.Join(db.dir, id, "hostconfig.json")
		hsFile, err := os.OpenFile(cFile, syscall.O_TRUNC|syscall.O_RDWR, 0)
		if err != nil {
			return fmt.Errorf("open %s: %v", cFile, err)
		}
		defer hsFile.Close()
		if err := json.NewEncoder(hsFile).Encode(cnt.HostConfig); err != nil {
			return err
		}
	}
	return nil
}

func (db *containersDB) Migrate(cnt *Container) error {
	hasLinks, err := cnt.HostConfig.HasLinks()
	if err != nil {
		return err
	}
	if hasLinks {
		return nil
	}
	fullName := cnt.Name
	if fullName[0] != '/' {
		fullName = "/" + fullName
	}

	children, err := db.graph.Children(fullName, 0)
	if err != nil {
		if !strings.Contains(err.Error(), "Cannot find child for") {
			return err
		}
		// else continue... it's ok if we didn't find any children, it'll just be nil and we can continue the migration
	}

	// don't use a nil slice, this ensures that the check above will skip once the migration has completed
	links := []string{}
	for _, child := range children {
		c, ok := db.cnts[child.Entity.ID()]
		if !ok {
			return fmt.Errorf("%s not found", child.Entity.ID())
		}

		links = append(links, c.Name+":"+child.Edge.Name)
	}

	cnt.HostConfig["Links"] = links
	return nil
}

func (db *containersDB) MigrateAll() error {
	for _, c := range db.cnts {
		if err := db.Migrate(c); err != nil {
			return err
		}
	}
	return nil
}

func readHostConfig(file string) (HostConfig, error) {
	hs, err := os.Open(file)
	if err != nil {
		return nil, fmt.Errorf("open %s: %v", file, err)
	}
	defer hs.Close()
	c := make(HostConfig)
	if err := json.NewDecoder(hs).Decode(&c); err != nil {
		return nil, fmt.Errorf("json from %s: %v", file, err)
	}
	return c, nil
}

func readConfig(file string) (*Container, error) {
	cfg, err := os.Open(file)
	if err != nil {
		return nil, fmt.Errorf("open %s: %v", file, err)
	}
	defer cfg.Close()
	var c Container
	if err := json.NewDecoder(cfg).Decode(&c); err != nil {
		return nil, fmt.Errorf("json from %s: %v", file, err)
	}
	return &c, nil
}
