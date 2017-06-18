#!/usr/bin/env bash
########################################################################################
# Runs inside a Docker container. Installs handler binaries.
#
# Environment:
# BLUEMIX_APP_MGMT_INSTALL - Handlers to install, '+' delimited list.
# OUT_USER, OUT_GROUP      - uid and gid to apply to output files.
#
# Required volume mounts:
# /app/.app-management - Contains the source app management directory.
# /out                 - Output directory. Installed handlers will be generated to
#                        /out/.app-management/handlers/
#
########################################################################################
set -e

now() {
  echo $(date +'%s')
}

app_mgmt_to_list() {
  echo "$1" | tr "+" " "
}

install_handlers() {
  local handler_list=$(app_mgmt_to_list "$BLUEMIX_APP_MGMT_INSTALL")
  echo "::::Install utilities: '${BLUEMIX_APP_MGMT_INSTALL}' ($handler_list)::::"

  TSTART=$(date +'%s')

  # Install handlers
  cp -dR /app/.app-management /out
  /out/.app-management/utils/install_handlers.rb /out/.app-management/handlers $handler_list

  echo "Fix owner..."
  chown -Rf ${OUT_USER}:${OUT_GROUP} /out/.app-management || true

  TEND=$(date +'%s')

  echo "Finished installing utilities (took $(( $TEND - $TSTART )) seconds)"
  echo "----"
}

install_handlers
