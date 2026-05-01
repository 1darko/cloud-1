[myhosts]
%{ for ip in ips ~}
${ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
%{ endfor ~}