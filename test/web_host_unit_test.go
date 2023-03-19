//go:build unit
// +build unit

package test

import (
	"fmt"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"testing"
	"time"
)

const outputCloudFrontDomain = "web_host_staging_cf_url"
const terraformDirectoryPath = "../terraform/staging"

func TestTerraformS3HostAccess(t *testing.T) {
	t.Parallel()

	test_structure.RunTestStage(t, "setup", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: terraformDirectoryPath,
		}
		test_structure.SaveTerraformOptions(t, terraformDirectoryPath, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, terraformDirectoryPath)
		terraform.Destroy(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "validate", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, terraformDirectoryPath)
		domain := terraform.Output(t, terraformOptions, outputCloudFrontDomain)
		SendGetRequest(t, domain, "", 200)
	})

}

func SendGetRequest(t *testing.T, domain string, path string, expectedStatusCode int) {
	url := fmt.Sprintf("%s://%s/%s", "http", domain, path)
	maxRetries := 6
	sleepBetweenRepeats := 5 * time.Second
	actionDescription := fmt.Sprintf("Access %s", url)
	retry.DoWithRetry(t, actionDescription, maxRetries, sleepBetweenRepeats, func() (string, error) {
		statusCode, _ := http_helper.HttpGet(t, url, nil)
		if statusCode == expectedStatusCode {
			t.Logf("response status code: %v URL: %v", statusCode, url)
			return "", nil
		}
		return "", fmt.Errorf("error. response status code %d  expected %d URL: %s", statusCode, expectedStatusCode, url)
	})
}
