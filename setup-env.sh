#!/usr/bin/env bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
# Echoes all commands before executing.
set -o verbose

# This script setup environment for WSO2 product deployment
readonly USERNAME=$2
readonly WUM_USER=$4
readonly WUM_PASS=$6
readonly LIB_DIR=/home/${USERNAME}/lib

install_packages() {

    apt-get update -y
    apt install unzip -y
    apt install git -y
    apt install mysql-client -y
}

install_wum() {

    echo "127.0.0.1 $(hostname)" >> /etc/hosts
    wget -P ${LIB_DIR} https://product-dist.wso2.com/downloads/wum/1.0.0/wum-1.0-linux-x64.tar.gz
    cd /usr/local/
    tar -zxvf "${LIB_DIR}/wum-1.0-linux-x64.tar.gz"
    chown -R ${USERNAME} wum/
    
    local is_path_set=$(grep -r "usr/local/wum/bin" /etc/profile | wc -l  )
    echo ">> Adding WUM installation directory to PATH ..."
    if [ ${is_path_set} = 0 ]; then
        echo ">> Adding WUM installation directory to PATH variable"
        echo "export PATH=\$PATH:/usr/local/wum/bin" >> /etc/profile
    fi
    source /etc/profile
    echo ">> Initializing WUM ..."
    sudo -u ${USERNAME} /usr/local/wum/bin/wum init -u ${WUM_USER} -p ${WUM_PASS}
}

install_java8() {

    readonly local jdk_filename='jdk-8u144-linux-x64.tar.gz'
    readonly local java_installer_dir='/usr/lib/jvm/java-8-oracle'

    # TODO: Need to get a proper way to retrieve JAVA 8
    wget -P ${LIB_DIR} https://www.dropbox.com/s/e5sdv8f7p1ifnkf/jdk-8u144-linux-x64.tar.gz

    mkdir -p /tmp/jdk/
    cd /tmp/jdk
    sudo tar -zxvf ${LIB_DIR}/${jdk_filename}

    echo ">> JAVA installation path: ${java_installer_dir}"
    mkdir -p ${java_installer_dir}
    mv ./$(ls)/* ${java_installer_dir}

    JAVA_HOME_FOUND=$(grep -r "JAVA_HOME=" /etc/environment | wc -l  )
    echo ">> Setting up JAVA_HOME ..."
    if [ ${JAVA_HOME_FOUND} = 0 ]; then
        echo ">> Adding JAVA_HOME entry."
        echo JAVA_HOME=${java_installer_dir} >> /etc/environment
    else
        echo ">> Updating JAVA_HOME entry."
        sed -i "/JAVA_HOME=/c\JAVA_HOME=${java_installer_dir}" /etc/environment
    fi
    source /etc/environment

    echo ">> Setting java userPrefs ..."
    mkdir -p /tmp/.java/.systemPrefs
    mkdir /tmp/.java/.userPrefs
    sudo -u ${USERNAME} chmod -R 755 /tmp/.java
    echo "export JAVA_OPTS='-Djava.util.prefs.systemRoot=/tmp/.java/ -Djava.util.prefs.userRoot=/tmp/.java/.userPrefs'" >> /etc/profile
    source /etc/profile
}

get_mysql_jdbc_driver() {

    wget -P ${LIB_DIR} http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.44/mysql-connector-java-5.1.44.jar
}

main() {

    mkdir -p ${LIB_DIR}

    install_packages
    install_wum
    install_java8
    get_mysql_jdbc_driver

    echo "Done!"
}

main