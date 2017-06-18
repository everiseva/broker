#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
CF_STACK=cloudfoundry/cflinuxfs2

set -e

cleanup() {
  [[ -d $output_dir ]] && rm -rf "$output_dir"
}

# Builds and runs a Docker image that installs the handler binaries under the CF stack.
# Outputs the binaries to $APP_MANAGEMENT_DIR/handlers/.
#
# Usage: build_handlers APP_MANAGEMENT_DIR HANDLERS_LIST
#   where HANDLERS_LIST is '+' delimited
build_handlers () {
  app_mgmt=$1
  handler_list=$2

  [[ -z $app_mgmt ]] && echo "Missing argument" >&2 && return 1
  [[ -z $handler_list ]] && echo "Warning: no handlers were specified to install" >&2
  if ! [[ -d $app_mgmt/handlers && -d $app_mgmt/node && -d $app_mgmt/utils ]]; then
    echo "$app_mgmt dir is missing one of: {handlers, node, utils}" >&2
    return 1
  fi

  output_dir=$(mktemp -d)
  trap cleanup 'RETURN'

  set -x
  docker run \
    -e BLUEMIX_APP_MGMT_INSTALL="${handler_list}" \
    -e OUT_USER="$(id -u)" \
    -e OUT_GROUP="$(id -g)" \
    -v ${SCRIPT_DIR}/install_handlers.sh:/install_handlers.sh:ro \
    -v ${app_mgmt}:/app/.app-management:ro \
    -v ${output_dir}:/out \
    --rm \
    ${CF_STACK} \
    /install_handlers.sh
  set +x

  # Now copy the built handlers /output/.app-management/handlers back into $app_mgmt
  echo "Copy built handlers"
  cp -dR ${output_dir}/.app-management/handlers/* ${app_mgmt}/handlers
}

build_handlers $@