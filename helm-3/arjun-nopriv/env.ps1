$Env:DOCKER_TLS_VERIFY = 1
$Env:COMPOSE_TLS_VERSION = "TLSv1_2"
$Env:DOCKER_CERT_PATH = Split-Path $script:MyInvocation.MyCommand.Path
$Env:DOCKER_HOST = "tcp://test-ucp.lab.capstonec.net:443"

$d = Split-Path $script:MyInvocation.MyCommand.Path
if (Get-Command kubectl -ErrorAction Ignore) {
        $Env:KUBECONFIG = $null
        kubectl config set-cluster ucp_test-ucp.lab.capstonec.net:6443_arjun-nopriv --server https://test-ucp.lab.capstonec.net:6443 --certificate-authority "$(Join-Path $d ca.pem)" --embed-certs
        kubectl config set-credentials ucp_test-ucp.lab.capstonec.net:6443_arjun-nopriv --client-key "$(Join-Path $d key.pem)" --client-certificate "$(Join-Path $d cert.pem)" --embed-certs
        kubectl config set-context ucp_test-ucp.lab.capstonec.net:6443_arjun-nopriv --user ucp_test-ucp.lab.capstonec.net:6443_arjun-nopriv --cluster ucp_test-ucp.lab.capstonec.net:6443_arjun-nopriv
}
$Env:KUBECONFIG = Join-Path $d kube.yml

#
# Bundle for user arjun-nopriv
# UCP Instance ID saglbp0vlmk49n0clpopam8nv
#
# Run this command from within this directory to configure your shell:
# Import-Module .\env.ps1
