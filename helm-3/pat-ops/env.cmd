@echo off
set DOCKER_TLS_VERIFY=1
set COMPOSE_TLS_VERSION=TLSv1_2
set DOCKER_CERT_PATH=%~dp0
set DOCKER_HOST=tcp://test-ucp.lab.capstonec.net:443

kubectl >nul 2>&1
if %ERRORLEVEL% == 0 (
    set KUBECONFIG=
    kubectl config set-cluster ucp_test-ucp.lab.capstonec.net:6443_pat-ops --server https://test-ucp.lab.capstonec.net:6443 --certificate-authority "%~dp0ca.pem" --embed-certs
    kubectl config set-credentials ucp_test-ucp.lab.capstonec.net:6443_pat-ops --client-key "%~dp0key.pem" --client-certificate "%~dp0cert.pem" --embed-certs
    kubectl config set-context ucp_test-ucp.lab.capstonec.net:6443_pat-ops --user ucp_test-ucp.lab.capstonec.net:6443_pat-ops --cluster ucp_test-ucp.lab.capstonec.net:6443_pat-ops
)
set KUBECONFIG=%~dp0kube.yml

REM
REM Bundle for user pat-ops
REM UCP Instance ID saglbp0vlmk49n0clpopam8nv
REM
REM Run this command from within this directory to configure your shell:
REM .\env.cmd
