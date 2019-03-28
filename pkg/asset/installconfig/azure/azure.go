package azure

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"sort"
	"strings"

	azureenv "github.com/Azure/go-autorest/autorest/azure"
	"github.com/Azure/go-autorest/autorest/azure/auth"
	"github.com/openshift/installer/pkg/types/azure"
	"github.com/openshift/installer/pkg/types/azure/validation"

	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	survey "gopkg.in/AlecAivazis/survey.v1"
)

const (
	defaultRegion string = "eastus"
)

var authFileLocation = os.Getenv("HOME") + "/.azure/osServicePrincipal.json"

// Platform collects azure-specific configuration.
func Platform() (*azure.Platform, error) {
	longRegions := make([]string, 0, len(validation.Regions))
	shortRegions := make([]string, 0, len(validation.Regions))
	for id, location := range validation.Regions {
		longRegions = append(longRegions, fmt.Sprintf("%s (%s)", id, location))
		shortRegions = append(shortRegions, id)
	}
	regionTransform := survey.TransformString(func(s string) string {
		return strings.SplitN(s, " ", 2)[0]
	})

	_, ok := validation.Regions[defaultRegion]
	if !ok {
		return nil, errors.Errorf("installer bug: invalid default azure region %q", defaultRegion)
	}

	_, err := GetSession()
	if err != nil {
		return nil, err
	}

	sort.Strings(longRegions)
	sort.Strings(shortRegions)

	var region string
	err = survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Select{
				Message: "Region",
				Help:    "The azure region to be used for installation.",
				Default: fmt.Sprintf("%s (%s)", defaultRegion, validation.Regions[defaultRegion]),
				Options: longRegions,
			},
			Validate: survey.ComposeValidators(survey.Required, func(ans interface{}) error {
				choice := regionTransform(ans).(string)
				i := sort.SearchStrings(shortRegions, choice)
				if i == len(shortRegions) || shortRegions[i] != choice {
					return errors.Errorf("invalid region %q", choice)
				}
				return nil
			}),
			Transform: regionTransform,
		},
	}, &region)
	if err != nil {
		return nil, err
	}

	return &azure.Platform{
		Region: region,
	}, nil
}

// GetSession returns an azure session by checking credentials
// and, if no creds are found, asks for them and stores them on disk in a config file
func GetSession() (*azure.Session, error) {
	err := getCredentials()
	if err != nil {
		return nil, err
	}
	return newSessionFromFile()
}

func newSessionFromFile() (*azure.Session, error) {
	os.Setenv("AZURE_AUTH_LOCATION", authFileLocation)
	authorizer, err := auth.NewAuthorizerFromFileWithResource(azureenv.PublicCloud.ResourceManagerEndpoint)
	if err != nil {
		return nil, errors.Wrap(err, "Can't initialize authorizer")
	}
	authInfo := &azureCredentials{}
	authBytes, err := ioutil.ReadFile(authFileLocation)
	if err != nil {
		return nil, errors.Wrapf(err, "Can't read azure authorization file : %s", authFileLocation)
	}
	err = json.Unmarshal(authBytes, authInfo)
	if err != nil {
		return nil, errors.Wrap(err, "Can't get authinfo")
	}
	session := azure.Session{
		SubscriptionID: authInfo.SubscriptionID,
		Authorizer:     authorizer,
	}
	return &session, nil
}

type azureCredentials struct {
	SubscriptionID string `json:"subscriptionId,omitempty"`
	ClientID       string `json:"clientId,omitempty"`
	ClientSecret   string `json:"clientSecret,omitempty"`
	TenantID       string `json:"tenantId,omitempty"`
}

func getCredentials() error {
	if _, err := os.Stat(authFileLocation); err == nil {
		return nil
	}

	var subscriptionID, tenantID, clientID, clientSecret string

	err := survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Input{
				Message: "azure subscription id",
				Help:    "The azure subscription id to use for installation",
			},
		},
	}, &subscriptionID)
	if err != nil {
		return err
	}

	err = survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Input{
				Message: "azure tenant id",
				Help:    "The azure tenant id to use for installation",
			},
		},
	}, &tenantID)
	if err != nil {
		return err
	}

	err = survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Input{
				Message: "azure service principal client id",
				Help:    "The azure client id to use for installation (this is not your username)",
			},
		},
	}, &clientID)
	if err != nil {
		return err
	}

	err = survey.Ask([]*survey.Question{
		{
			Prompt: &survey.Password{
				Message: "azure service principal client secret",
				Help:    "The azure secret access key corresponding to your client secret (this is not your password).",
			},
		},
	}, &clientSecret)
	if err != nil {
		return err
	}

	jsonCreds, err := json.Marshal(azureCredentials{
		SubscriptionID: subscriptionID,
		ClientID:       clientID,
		ClientSecret:   clientSecret,
		TenantID:       tenantID,
	})

	logrus.Infof("Writing azure credentials to %q", authFileLocation)
	err = os.MkdirAll(filepath.Dir(authFileLocation), 0700)
	if err != nil {
		logrus.Error(err)
		return err
	}

	err = ioutil.WriteFile(authFileLocation, jsonCreds, 0600)
	if err != nil {
		logrus.Error(err)
		return err
	}
	return nil
}
