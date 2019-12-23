export DOCKER_TLS_VERIFY=1
export COMPOSE_TLS_VERSION=TLSv1_2
export DOCKER_CERT_PATH=$PWD
export DOCKER_HOST=tcp://test-ucp.lab.capstonec.net:443

if kubectl >/dev/null 2>&1; then
    unset KUBECONFIG
    kubectl config set-cluster ucp_test-ucp.lab.capstonec.net:6443_joe-dev --server https://test-ucp.lab.capstonec.net:6443 --certificate-authority "$PWD/ca.pem" --embed-certs
    kubectl config set-credentials ucp_test-ucp.lab.capstonec.net:6443_joe-dev --client-key "$PWD/key.pem" --client-certificate "$PWD/cert.pem" --embed-certs
    kubectl config set-context ucp_test-ucp.lab.capstonec.net:6443_joe-dev --user ucp_test-ucp.lab.capstonec.net:6443_joe-dev --cluster ucp_test-ucp.lab.capstonec.net:6443_joe-dev
fi
export KUBECONFIG=$PWD/kube.yml

#
# Bundle for user joe-dev
# UCP Instance ID saglbp0vlmk49n0clpopam8nv
#
# Run this command from within this directory to configure your shell:
# eval "$(<env.sh)"
