docker_reddit:
  hosts:
%{ for i,name in ipaddr ~}
    ${namehost}-${i + 1}:
         ansible_host: ${name}
%{ endfor~}
