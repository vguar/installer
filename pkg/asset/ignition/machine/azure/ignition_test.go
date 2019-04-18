package azure

import (
	"fmt"
	"net/url"
	"testing"

	igntypes "github.com/coreos/ignition/config/v2_2/types"
	"github.com/stretchr/testify/assert"
)

func TestMasterGenerate(t *testing.T) {
	cfg := &igntypes.Config{
		Ignition: igntypes.Ignition{
			Version: igntypes.MaxVersion.String(),
			Config: igntypes.IgnitionConfig{
				Append: []igntypes.ConfigReference{{
					Source: func() *url.URL {
						return &url.URL{
							Scheme: "https",
							Host:   fmt.Sprintf("api.%s:22623", "domain.io"),
							Path:   fmt.Sprintf("/config/%s", "master"),
						}
					}().String(),
				}},
			},
		},
	}

	Ignition(cfg)

	assert.Equal(t, 1, len(cfg.Storage.Files))
	assert.Equal(t, "/etc/resolv.conf", cfg.Storage.Files[0].Path)
}
