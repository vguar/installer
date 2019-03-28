package azure

import "github.com/Azure/go-autorest/autorest"

//Session is an object representing session for subscription
type Session struct {
	SubscriptionID string
	Authorizer     autorest.Authorizer
}

//DNSConfig is an interface that provides means to fetch the DNS settings
type DNSConfig struct {
	Session Session
}

//GetBaseDomain returns the base domain to use
func (config DNSConfig) GetBaseDomain() (string, error) {
	return "", nil
}

//GetPublicZone returns the public zone id to create subdomain during deployment
func (config DNSConfig) GetPublicZone(name string) string { //returns ID
	return ""
}
