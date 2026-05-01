TERRA_PATH=./terraform/
ANSIBLE_PATH=./ansible

all:
	cd $(TERRA_PATH) && terraform init && terraform apply -auto-approve
	echo "Lil wait time for the machines to be up and running"
	sleep 60
	cd $(ANSIBLE_PATH) && pwd && ansible-playbook -i inventory.ini playbook.yaml

down:
	cd $(TERRA_PATH) && terraform apply -auto-approve -var="instance_state=stopped"

up:
	cd $(TERRA_PATH) && terraform apply -auto-approve -var="instance_state=running"

destory:
	cd $(TERRA_PATH) && terraform destroy -auto-approve

re: destory all

.PHONY: all down destroy