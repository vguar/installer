package azure

import (
	igntypes "github.com/coreos/ignition/config/v2_2/types"
	ignition "github.com/openshift/installer/pkg/asset/ignition"
)

// Ignition adds azure specific ignition config
func Ignition(cfg *igntypes.Config) {
	appendResolvConf(cfg)
}

func appendResolvConf(cfg *igntypes.Config) {
	overwrite := true
	file := ignition.FileFromString("/etc/resolv.conf", "root", 420, "nameserver 168.63.129.16")
	file.Overwrite = &overwrite
	cfg.Storage.Files = append(cfg.Storage.Files, file)
}
