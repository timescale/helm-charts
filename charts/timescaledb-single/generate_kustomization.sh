#!/bin/sh

# This file and its contents are licensed under the Apache License 2.0.
# Please see the included NOTICE for copyright information and LICENSE for a copy of the license.
#
# The purpose of this script is to create a kustomization specifically for a
# single deployment. It does this by copying the example kustomization,
# renaming the relevant bits, and generating (random) credentials and certificates
export LC_ALL=C

if test "$1" = "";
then
    cat <<__EOT__
Usage: $0 NAME [KUSTOMIZATION DIRECTORY]"

Example:

$0 my-deployment
$0 my-deployment /secrets/my-deployment/
__EOT__
    exit 1
fi
DEPLOYMENT="$1"
shift

KUSTOMIZE_DIR="$1"
KUSTOMIZE_ROOT="$(dirname "$0")/kustomize"
if test "${KUSTOMIZE_DIR}" = "";
then
    KUSTOMIZE_DIR="${KUSTOMIZE_ROOT}/${DEPLOYMENT}"
fi

test -d "${KUSTOMIZE_DIR}" \
    && echo "The directory \"${KUSTOMIZE_DIR}\" already exists. This tool will not overwrite a current kustomization." \
    && exit 1

mkdir -p "${KUSTOMIZE_DIR}"
sed "s/example/${DEPLOYMENT}/" "${KUSTOMIZE_ROOT}/example/kustomization.yaml" > "${KUSTOMIZE_DIR}/kustomization.yaml"

generate_credentials() {
    touch "$1"

    for key in PATRONI_SUPERUSER_PASSWORD PATRONI_REPLICATION_PASSWORD PATRONI_admin_PASSWORD
    do
        echo "${key}=$(< /dev/urandom LC_CTYPE=C tr -dc A-Za-z0-9 | head -c32)" >> "$1"
    done
}

generate_certificate () {
    openssl req -x509 -newkey rsa:4096 -keyout "$1/tls.key" -out "$1/tls.crt" -days 1 -nodes -subj "/CN=$2"
}

generate_pgbackrest () {
    touch "$1"

    test "${SKIP_PGBACKREST_CONFIG}" = "" || return

    while true
    do
        echo "Do you want to configure the backup of your database to S3 (compatible) storage? (y/n)"
        read response
        case "$response" in
            y*) break ;;
            Y*) break ;;
            n*) return ;;
            N*) return ;;
            *) ;;
        esac
    done
        cat <<__EOT__
We'll be asking a few questions about S3 buckets, keys, secrets and endpoints.

For background information, visit these pages:

Amazon Web Services:
- https://docs.aws.amazon.com/AmazonS3/latest/gsg/CreatingABucket.html
- https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html

Digital Ocean:
- https://developers.digitalocean.com/documentation/spaces/#aws-s3-compatibility

Google Cloud:
- https://cloud.google.com/storage/docs/migrating#migration-simple


__EOT__
    echo

    echo "What is the name of the S3 bucket?"
    read BUCKET

    echo "What is the name of the S3 endpoint? (leave blank for default)"
    read ENDPOINT

    echo "What is the region of the S3 endpoint? (leave blank for default)"
    read REGION

    echo "What is the S3 Key to use?"
    read KEY

    echo "What is the S3 Secret to use?"
    read KEY_SECRET

    for key in BUCKET ENDPOINT REGION KEY KEY_SECRET
    do
        eval "VALUE=\${$key}"
        test "${VALUE}" = "" || echo "PGBACKREST_REPO1_S3_${key}=${VALUE}" >> "$1"
    done
}

print_install_instructions() {
    cat <<__EOT__

To install these secrets, execute:

    kubectl apply -k "${KUSTOMIZE_DIR}"

__EOT__
}

install_secrets() {
    echo "Installing secrets..."
    kubectl apply -k "${KUSTOMIZE_DIR}"
}

print_info() {
    cat <<__EOT__

Generated a kustomization named ${DEPLOYMENT} in directory ${KUSTOMIZE_DIR}.


WARNING: The generated certificate in this directory is self-signed and is only
         fit for development and demonstration purposes.
         The certificate should be replaced by a signed certificate, signed by
         a Certificate Authority (CA) that you trust.


You may now wish to (p)review the files that have been created and further edit
them before deployment.


To preview the deployment of the secrets:

    kubectl kustomize "${KUSTOMIZE_DIR}"

__EOT__
}

generate_credentials "${KUSTOMIZE_DIR}/credentials.conf"
generate_certificate "${KUSTOMIZE_DIR}" "${DEPLOYMENT}"
generate_pgbackrest "${KUSTOMIZE_DIR}/pgbackrest.conf"

print_info

if [ -n "${SKIP_INSTALL}" ]
then
    print_install_instructions
    exit 0
fi

while true
do
    echo "Or you may want to install the secrets directly? (y/n)"
    read response
    case "$response" in
        y*) break ;;
        Y*) break ;;
        n*) 
            print_install_instructions
            exit 0 ;;
        N*) 
            print_install_instructions
            exit 0 ;;
        *) ;;
    esac
done

install_secrets