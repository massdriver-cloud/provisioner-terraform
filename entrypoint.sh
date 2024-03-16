#!/bin/bash

set -eo pipefail

case $PROVISIONER_ACTION in
    apply )
        command=apply
        ;;
    destroy )
        command=destroy
        ;;
    *)
        echo "Unsupported action: $action"
        exit 1
        ;;
esac

echo "copying variables files"
cp /src/bundles/connections.json _connections.auto.tfvars.json
cp /src/bundles/params.json _params.auto.tfvars.json

tf_flags=""
if [ $command = "destroy" ]; then
    tf_flags="-destroy"
fi

echo "executing terraform init"
terraform init -no-color -input=false
echo "executing terraform plan"
terraform plan $tf_flags -out tf.plan -json
echo "executing terraform apply"
terraform apply $tf_flags -json tf.plan

rm _connections.auto.tfvars.json
rm _params.auto.tfvars.json