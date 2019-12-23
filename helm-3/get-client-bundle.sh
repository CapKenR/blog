#!/bin/bash
AUTHTOKEN=$(curl -sk -d '{"username":"$1","password":"$2"}' https://test-ucp.lab.capstonec.net/auth/login | jq -r .auth_token)
curl -k -H "Authorization: Bearer $AUTHTOKEN" https://test-ucp.lab.capstonec.net/api/clientbundle -o $1_bundle.zip
