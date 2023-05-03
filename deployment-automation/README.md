cd deployment-automation/account1
terraform init
terraform apply (vor prcnum a mi 30 varkyan spasum es initialize lini)
brew install gnu-tar  
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
ansible-playbook --private-key ~/.ssh/id_rsa -i ../hosts.ini -v ansible/provision-node.yml           
ansible-playbook --private-key ~/.ssh/id_rsa -i ../hosts.ini -v ansible/deploy-prometheus-grafana.yml
ansible-playbook --private-key ~/.ssh/id_rsa -i ../hosts.ini -v ansible/provision-clickhouse.yml  


