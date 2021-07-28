package test

import (
	"fmt"
	"math/rand"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()

	rand.Seed(time.Now().UnixNano())
	randID := strconv.Itoa(rand.Intn(100000))
	attributes := []string{randID}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
		// We always include a random attribute so that parallel tests
		// and AWS resources do not interfere with each other
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	id := terraform.Output(t, terraformOptions, "id")
	transfer_endpoint := terraform.Output(t, terraformOptions, "transfer_endpoint")

	// Verify we're getting back the outputs we expect
	// Ensure we get a random number appended
	expectedTransferEndpoint := "server.transfer.us-east-2.amazonaws.com"
	assert.True(t,
		strings.HasSuffix(transfer_endpoint, expectedTransferEndpoint),
		fmt.Sprintf("Transfer endpoint should end with %v", expectedTransferEndpoint))

	// Ensure we get the attribute included in the ID
	assert.Equal(t, "eg-ue2-test-example-"+randID, id)

	// ************************************************************************
	// This steps below are unusual, not generally part of the testing
	// but included here as an example of testing this specific module.
	// This module has a random number that is supposed to change
	// only when the example changes. So we run it again to ensure
	// it does not change.

	// This will run `terraform apply` a second time and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	id2 := terraform.Output(t, terraformOptions, "id")
	transfer_endpoint2 := terraform.Output(t, terraformOptions, "transfer_endpoint")

	assert.Equal(t, id, id2, "Expected `id` to be stable")
	assert.Equal(t, transfer_endpoint, transfer_endpoint2, "Expected `transfer_endpoint` to be stable")
}
