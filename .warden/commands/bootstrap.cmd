#!/usr/bin/env bash
[[ ! ${WARDEN_DIR} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!\033[0m" && exit 1
set -euo pipefail

function :: {
  echo
  echo "==> [$(date +%H:%M:%S)] $@"
}

## load configuration needed for setup
WARDEN_ENV_PATH="$(locateEnvPath)" || exit $?
loadEnvConfig "${WARDEN_ENV_PATH}" || exit $?

assertDockerRunning

## change into the project directory
cd "${WARDEN_ENV_PATH}"

## configure command defaults
WARDEN_WEB_ROOT="$(echo "${WARDEN_WEB_ROOT:-/}" | sed 's#^/#./#')"
WARDEN_ENV_NAME="$(echo "${WARDEN_ENV_NAME:-/}")"
REQUIRED_FILES=""
##("${WARDEN_WEB_ROOT}/restore.php")
DB_DUMP="${DB_DUMP:-./backfill/magento-db.sql.gz}"
BACKUP_URL=""
DB_IMPORT=1
CLEAN_INSTALL=
AUTO_PULL=1
META_PACKAGE="magento/project-community-edition"
META_VERSION=""
URL_FRONT="https://${TRAEFIK_SUBDOMAIN}.${TRAEFIK_DOMAIN}/"
URL_ADMIN="https://${TRAEFIK_SUBDOMAIN}.${TRAEFIK_DOMAIN}/bitrix/"

## argument parsing
## parse arguments
while (( "$#" )); do
    case "$1" in
        --clean-install)
            ##REQUIRED_FILES+=("${WARDEN_WEB_ROOT}/bitrix/.settings.php.init.php")
            CLEAN_INSTALL=1
            DB_IMPORT=
            shift
            ;;
        --meta-package)
            shift
            META_PACKAGE="$1"
            shift
            ;;
        --meta-version)
            shift
            META_VERSION="$1"
            if
                ! test $(version "${META_VERSION}") -ge "$(version 2.3.4)" \
                && [[ ! "${META_VERSION}" =~ ^2\.[3-9]\.x$ ]]
            then
                fatal "Invalid --meta-version=${META_VERSION} specified (valid values are 2.3.4 or later and 2.[3-9].x)"
            fi
            shift
            ;;
        --skip-db-import)
            DB_IMPORT=
            shift
            ;;
        --db-dump)
            shift
            DB_DUMP="$1"
            shift
            ;;
        --no-pull)
            AUTO_PULL=
            shift
            ;;
        --load-backup)
            shift
            BACKUP_URL="$1"
            shift
            ;;
        *)
            error "Unrecognized argument '$1'"
            exit -1
            ;;
    esac
done

## if no composer.json is present in web root imply --clean-install flag when not specified explicitly
if [[ ! ${CLEAN_INSTALL} ]] && [[ ! -f "${WARDEN_WEB_ROOT}/composer.json" ]]; then
  warning "Implying --clean-install since file ${WARDEN_WEB_ROOT}/composer.json not present"
  ##REQUIRED_FILES+=("${WARDEN_WEB_ROOT}/bitrix/.settings.php.init.php")
  CLEAN_INSTALL=1
  DB_IMPORT=
fi

## include check for DB_DUMP file only when database import is expected
[[ ${DB_IMPORT} ]] && REQUIRED_FILES+=("${DB_DUMP}" "${WARDEN_WEB_ROOT}/app/etc/env.php.warden.php")

##TMPLT=exampleproject
##RPLC=${WARDEN_ENV_NAME}-db-1
##sed -i -r "s/$TMPLT/$RPLC/g" ${WARDEN_WEB_ROOT}/restore.php

:: Verifying configuration
INIT_ERROR=

## verify warden version constraint
WARDEN_VERSION=$(den version 2>/dev/null) || true
WARDEN_REQUIRE=in-dev
if ! test $(version ${WARDEN_VERSION}) -ge $(version ${WARDEN_REQUIRE}); then
  error "Warden ${WARDEN_REQUIRE} or greater is required (version ${WARDEN_VERSION} is installed)"
  INIT_ERROR=1
fi

## check for presence of local configuration files to ensure they exist
for REQUIRED_FILE in ${REQUIRED_FILES[@]}; do
  if [[ ! -f "${REQUIRED_FILE}" ]]; then
    error "Missing local file: ${REQUIRED_FILE}"
    INIT_ERROR=1
  fi
done

## exit script if there are any missing dependencies or configuration files
[[ ${INIT_ERROR} ]] && exit 1

if ls backfill/*.tar.* 1> /dev/null 2>&1; then
  cp backfill/*.tar.* ${WARDEN_WEB_ROOT}/
else
  echo 'Backup files not found'
fi

:: Starting Warden
den svc up
if [[ ! -f ~/.warden/ssl/certs/${TRAEFIK_DOMAIN}.crt.pem ]]; then
    den sign-certificate ${TRAEFIK_DOMAIN}
fi

:: Initializing environment
if [[ $AUTO_PULL ]]; then
  den env pull --ignore-pull-failures || true
  den env build --pull
else
  den env build
fi

den env up -d

echo ${BACKUP_URL}
if [[ ${BACKUP_URL} ]]; then
  :: Download backup
  den env exec -- -T php-fpm wget ${BACKUP_URL}
fi

if ! [ -f ${WARDEN_WEB_ROOT}/bitrixsetup.php ]; then
  den env exec -- -T php-fpm wget --no-check-certificate https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php
else
  echo "bitrixsetup.php exists."
fi

if ! [ -f ${WARDEN_WEB_ROOT}/restore.php ]; then
  den env exec -- -T php-fpm wget --no-check-certificate https://www.1c-bitrix.ru/download/scripts/restore.php
else
  echo "restore.php exists."
fi

## wait for mariadb to start listening for connections
den shell -c "while ! nc -z db 3306 </dev/null; do sleep 2; done"