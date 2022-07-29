package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"os"
	"strings"
	"testing"
)

func cleanup(t *testing.T, terraformOptions *terraform.Options, tempTestFolder string) {
	terraform.Destroy(t, terraformOptions)
	os.RemoveAll(tempTestFolder)
}

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

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
	assert.Equal(t, "eg-ue2-test-sftp-"+randID, id)

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

// Test the Terraform module in examples/vpc using Terratest.
func TestExamplesVPC(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/vpc"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

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
	assert.Equal(t, "eg-ue2-test-sftp-"+randID, id)

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
