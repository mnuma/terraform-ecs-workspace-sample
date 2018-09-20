.PHONY: help

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## init
	terraform init
	# terraform workspace new staging3
	# terraform workspace new staging2
	# terraform workspace new staging
	# terraform workspace new production

tf-staging: ## tf-staging
	terraform workspace select staging
	terraform workspace list

tf-staging-plan: tf-staging ## tf-staging-plan
	terraform plan -var-file=terraform.tfvars.staging

tf-staging-apply: tf-staging ## tf-staging-plan
	terraform apply -var-file=terraform.tfvars.staging

tf-staging2: ## tf-staging2
	terraform workspace select staging2
	terraform workspace list

tf-plan-staging2: tf-staging2 ## tf-plan-staging2
	terraform plan -var-file=terraform.tfvars.staging2

tf-apply-staging2: tf-staging2 ## tf-apply-staging2
	terraform apply -var-file=terraform.tfvars.staging2

tf-plan-destory-staging2: tf-staging2
	terraform plan -destroy -var-file=terraform.tfvars.staging2

tf-destory-staging2: tf-staging2
	terraform destroy -var-file=terraform.tfvars.staging2

tf-staging3: ## tf-staging3
	terraform workspace select staging3
	terraform workspace list

tf-plan-staging3: tf-staging3 ## tf-plan-staging3
	terraform plan -var-file=terraform.tfvars.staging3

tf-apply-staging3: tf-staging3 ## tf-apply-staging3
	terraform apply -var-file=terraform.tfvars.staging3

tf-plan-destory-staging3: tf-staging3
	terraform plan -destroy -var-file=terraform.tfvars.staging3

tf-destory-staging3: tf-staging3
	terraform destroy -var-file=terraform.tfvars.staging3

########################################################
## serivece deploy
########################################################

serivice-update-staging3: tf-staging3
	terraform apply -auto-approve -var-file=terraform.tfvars.staging3 \
	-target=aws_ecs_task_definition.sample_api -target=aws_ecs_service.sample_api_service
