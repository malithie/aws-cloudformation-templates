#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Echoes all commands before executing.
set -o verbose

readonly USERNAME=$1
readonly PRODUCT_NAME="wso2is"
readonly PRODUCT_VERSION="5.3.0"
readonly WUM_PRODUCT_NAME=${PRODUCT_NAME}-${PRODUCT_VERSION}
readonly WUM_PRODUCT_DIR=/home/${USERNAME}/.wum-wso2/products/${PRODUCT_NAME}/${PRODUCT_VERSION}
readonly INSTALLATION_DIR=/opt/wso2
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"

# MYSQL connection details
readonly MYSQL_USERNAME="root"
readonly MYSQL_PASSWORD="root1234"
MYSQL_HOST=""

# MYSQL databases
readonly UM_DB="WSO2_UM_DB"
readonly IDENTITY_DB="WSO2_IDENTITY_DB"
readonly GOV_REG_DB="WSO2_GOV_REG_DB"
readonly BPS_DB="WSO2_BPS_DB"

# MYSQL database users
readonly UM_USER="wso2umuser"
readonly IDENTITY_USER="wso2identityuser"
readonly GOV_REG_USER="wso2registryuser"
readonly BPS_USER="wso2bpsuser"

setup_wum_updated_pack() {
    sudo -u ${USERNAME} /usr/local/wum/bin/wum add ${WUM_PRODUCT_NAME} -y
    sudo -u ${USERNAME} /usr/local/wum/bin/wum update ${WUM_PRODUCT_NAME}

    mkdir -p ${INSTALLATION_DIR}
    chown -R ${USERNAME} ${INSTALLATION_DIR}
    echo "Copying WUM updated ${WUM_PRODUCT_NAME} to ${INSTALLATION_DIR}"
    sudo -u ${USERNAME} unzip ${WUM_PRODUCT_DIR}/$(ls -t ${WUM_PRODUCT_DIR} | grep .zip | head -1) -d ${INSTALLATION_DIR}
}

setup_database() {

    cp $(find /home/${USERNAME}/bin/ -iname "mysql-connector*.jar" | head -n 1 ) ${PRODUCT_HOME}/lib/
}

start_product() {
    sudo -u ${USERNAME} bash ${PRODUCT_HOME}/bin/wso2server.sh start
}

main() {

    setup_wum_updated_pack
    start_product
}

main
