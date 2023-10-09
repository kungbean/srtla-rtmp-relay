#!/bin/bash

for template in $TEMPLATE_DIR/*.template; do
    dest=$(dirname $TEMPLATE_DIR)/$(basename $template .template)
    echo "Running envsubst on ${template} to ${dest}"
    envsubst < $template > $dest
done

exec "$@"
