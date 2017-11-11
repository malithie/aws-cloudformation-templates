#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Echoes all commands before executing.
set -o verbose

readonly USERNAME=$2
readonly MYSQL_HOST=$4
readonly IS_HOST_NAME=$6

readonly PRODUCT_NAME="wso2is"
readonly PRODUCT_VERSION="5.3.0"
readonly WUM_PRODUCT_NAME=${PRODUCT_NAME}-${PRODUCT_VERSION}
readonly WUM_PRODUCT_DIR=/home/${USERNAME}/.wum-wso2/products/${PRODUCT_NAME}/${PRODUCT_VERSION}
readonly INSTALLATION_DIR=/opt/wso2
readonly PRODUCT_HOME="${INSTALLATION_DIR}/${PRODUCT_NAME}-${PRODUCT_VERSION}"

# MYSQL connection details
readonly MYSQL_USERNAME="root"
readonly MYSQL_PASSWORD="root1234"

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
    echo ">> Copying WUM updated ${WUM_PRODUCT_NAME} to ${INSTALLATION_DIR}"
    sudo -u ${USERNAME} unzip ${WUM_PRODUCT_DIR}/$(ls -t ${WUM_PRODUCT_DIR} | grep .zip | head -1) -d ${INSTALLATION_DIR}
}

setup_databases() {

    echo ">> Creating databases..."
    mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "DROP DATABASE IF EXISTS $UM_DB; DROP DATABASE IF
    EXISTS $IDENTITY_DB; DROP DATABASE IF EXISTS $GOV_REG_DB; DROP DATABASE IF EXISTS $BPS_DB; CREATE DATABASE
    $UM_DB; CREATE DATABASE $IDENTITY_DB; CREATE DATABASE $GOV_REG_DB; CREATE DATABASE $BPS_DB;"
    echo ">> Databases created!"

    echo ">> Creating users..."
    mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "CREATE USER '$UM_USER'@'%' IDENTIFIED BY
    '$UM_USER'; CREATE USER '$IDENTITY_USER'@'%' IDENTIFIED BY '$IDENTITY_USER'; CREATE USER '$GOV_REG_USER'@'%'
    IDENTIFIED BY '$GOV_REG_USER'; CREATE USER '$BPS_USER'@'%' IDENTIFIED BY '$BPS_USER';"
    echo ">> Users created!"

    echo -e ">> Grant access for users..."
    mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $UM_DB.* TO '$UM_USER'@'%';
    GRANT ALL PRIVILEGES ON $IDENTITY_DB.* TO '$IDENTITY_USER'@'%'; GRANT ALL PRIVILEGES ON $GOV_REG_DB.* TO
    '$GOV_REG_USER'@'%'; GRANT ALL PRIVILEGES ON $BPS_DB.* TO '$BPS_USER'@'%';"
    echo ">> Access granted!"

    echo ">> Creating tables..."
    mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "USE $UM_DB; SOURCE dbscripts/mysql/um-mysql.sql;
    USE $IDENTITY_DB; SOURCE dbscripts/mysql/identity-mysql.sql; USE $GOV_REG_DB; SOURCE dbscripts/mysql/gov-registry-mysql.sql;
    USE $BPS_DB; SOURCE dbscripts/mysql/bps-mysql.sql;"
    echo ">> Tables created!"
}

copy_libs() {

    echo ">> Copying mysql jdbc driver "
    cp -v $(find /home/${USERNAME}/lib/ -iname "mysql-connector*.jar" | head -n 1 ) ${PRODUCT_HOME}/repository/components/lib
}

copy_config_files() {

    echo ">> Copying configuration files "
    cp -r -v conf/* ${PRODUCT_HOME}/repository/conf/
    echo ">> Done!"
}

configure_product() {

    echo ">> Configuring product "
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_IS_LB_HOSTNAME_#/'$IS_HOST_NAME'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_RDS_HOSTNAME_#/'$MYSQL_HOST'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_UM_DB_#/'$UM_DB'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_UM_USER_#/'$UM_USER'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_GOV_REG_DB_#/'$GOV_REG_DB'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_GOV_REG_USER_#/'$GOV_REG_USER'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_IDENTITY_DB_#/'$IDENTITY_DB'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_IDENTITY_USER_#/'$IDENTITY_USER'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_BPS_DB_#/'$BPS_DB'/g'
    find ${PRODUCT_HOME}/ -type f \( -iname "*.properties" -o -iname "*.xml" \) -print0 | xargs -0 sed -i 's/#_BPS_USER_#/'$BPS_USER'/g'
    echo "Done!"
}

start_product() {

    echo ">> Starting WSO2 Identity Server ... "
    sudo -u ${USERNAME} bash ${PRODUCT_HOME}/bin/wso2server.sh start
}

main() {

    setup_wum_updated_pack
    setup_databases
    copy_libs
    copy_config_files
    configure_product
    start_product
}

main
