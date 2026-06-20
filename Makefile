SHELL := /bin/bash

.PHONY: infra-init infra-plan infra-apply infra-destroy ping app deploy restart logs status

infra-init:
	cd opentofu && tofu init

infra-plan:
	cd opentofu && tofu plan

infra-apply:
	cd opentofu && tofu apply

infra-destroy:
	cd opentofu && tofu destroy

ping:
	cd ansible && ANSIBLE_CONFIG=ansible.cfg ansible all -m ping

app:
	cd ansible && ANSIBLE_CONFIG=ansible.cfg ansible-playbook site.yml

deploy: infra-apply app

restart:
	cd ansible && ANSIBLE_CONFIG=ansible.cfg ansible-playbook playbooks/restart.yml

logs:
	cd ansible && ANSIBLE_CONFIG=ansible.cfg ansible-playbook playbooks/logs.yml

status:
	cd ansible && ANSIBLE_CONFIG=ansible.cfg ansible-playbook playbooks/status.yml
