TF_DIR = terraform
ANSIBLE_DIR = ansible
KEY = $(abspath $(TF_DIR)/daw_key.pem)
INVENTORY = $(ANSIBLE_DIR)/inventory.yml

.PHONY: deploy apply configure destroy clean

deploy: apply configure

apply:
	terraform -chdir=$(TF_DIR) init
	terraform -chdir=$(TF_DIR) apply -auto-approve
	chmod 600 $(TF_DIR)/*.pem
	@printf 'all:\n  hosts:\n    %s:\n      ansible_user: ubuntu\n      ansible_ssh_private_key_file: "%s"\n' \
		"$$(terraform -chdir=$(TF_DIR) output -raw public_ip)" "$(KEY)" > $(INVENTORY)

configure:
	ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/playbook.yml

destroy:
	terraform -chdir=$(TF_DIR) destroy -auto-approve

clean:
	rm -rf $(TF_DIR)/.terraform $(TF_DIR)/.terraform.lock.hcl $(TF_DIR)/*.tfstate* $(INVENTORY) $(TF_DIR)/*.pem
