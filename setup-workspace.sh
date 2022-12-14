#!/usr/bin/env bash

# IBM GSI Ecosystem Lab

TEMPLATE_FLAVOR="small"
REF_ARCH="vpc"
PREFIX_NAME=""
REGION="eu-de"

Usage()
{
   echo "Creates a workspace folder and populates it with architectures."
   echo
   echo "Usage: setup-workspace.sh [-n PREFIX_NAME] [-r REGION]"
   echo "  options:"
   echo "  n     (optional) prefix that should be used for all variables"
   echo "  r     (optional) the region where the infrastructure will be provisioned"
   echo "  h     Print this help"
   echo
}

# Get the options
while getopts ":a:t:n:r:" option; do
   case $option in
      h) # display Help
         Usage
         exit 1;;
      t) # Enter a name
         TEMPLATE_FLAVOR=$OPTARG;;
      a) # Enter a name
         REF_ARCH=$OPTARG;;
      n) # Enter a name
         PREFIX_NAME=$OPTARG;;
      r) # Enter a name
         REGION=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         Usage
         exit 1;;
   esac
done

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
WORKSPACES_DIR="${SCRIPT_DIR}/../workspaces"
WORKSPACE_DIR="${WORKSPACES_DIR}/current"

echo ${SCRIPT_DIR}

if [[ -d "${WORKSPACE_DIR}" ]]; then
  DATE=$(date "+%Y%m%d%H%M")
  mv "${WORKSPACE_DIR}" "${WORKSPACES_DIR}/workspace-${DATE}"
fi

mkdir -p "${WORKSPACE_DIR}"
cd "${WORKSPACE_DIR}"

echo "Setting up workspace in '${WORKSPACE_DIR}'"
echo "*****"

if [[ -n "${PREFIX_NAME}" ]]; then
  PREFIX_NAME="${PREFIX_NAME}-"
fi

"${SCRIPT_DIR}/create-ssh-keys.sh"
cat "${SCRIPT_DIR}/terraform.tfvars.template-${TEMPLATE_FLAVOR}" | \
  sed "s/PREFIX/${PREFIX_NAME}/g"  | \
  sed "s/REGION/${REGION}/g" \
  > ./terraform.tfvars

# append random string into suffix variable in tfvars  to prevent name collisions in object storage buckets
if command -v openssl &> /dev/null
then
    printf "\n\nsuffix=\"$(openssl rand -hex 4)\"\n" >> "${WORKSPACE_DIR}"/terraform.tfvars
fi

# Help Scripts for applying and destroying
cp "${SCRIPT_DIR}/apply-all.sh" "${WORKSPACE_DIR}/apply-all.sh"
cp "${SCRIPT_DIR}/destroy-all.sh" "${WORKSPACE_DIR}/destroy-all.sh"
cp "${SCRIPT_DIR}/terragrunt.hcl" "${WORKSPACE_DIR}/terragrunt.hcl"

ALL_ARCH="000|100|110|120|130|140|150|160|165"

echo "Setting up workspace from '${TEMPLATE_FLAVOR}' template"
echo "*****"

WORKSPACE_DIR=$(cd "${WORKSPACE_DIR}"; pwd -P)

VPC_ARCH="000|100|110|120"
OCP_ARCH="000|100|110|130|150|160|165"
OCP_BASE_ARCH="000|100|110|130|150"

echo "Setting up automation  ${WORKSPACE_DIR}"

find "${SCRIPT_DIR}/." -type d -maxdepth 1 | grep -vE "[.][.]/[.].*" | grep -v workspace | sort | \
  while read dir;
do

  name=$(echo "$dir" | sed -E "s/.*\///")

  if [[ ! -d "${SCRIPT_DIR}/${name}/terraform" ]]; then
    continue
  fi

  if [[ "${REF_ARCH}" == "ocp-base" ]] && [[ ! "${name}" =~ ${OCP_BASE_ARCH} ]]; then
    continue
  fi

  if [[ "${REF_ARCH}" == "ocp" ]] && [[ ! "${name}" =~ ${OCP_ARCH} ]]; then
    continue
  fi

  if [[ "${REF_ARCH}" == "vpc" ]] && [[ ! "${name}" =~ ${VPC_ARCH} ]]; then
    continue
  fi

  if [[ "${REF_ARCH}" == "all" ]] && [[ ! "${name}" =~ ${VPC_ARCH}|${OCP_ARCH} ]]; then
    continue
  fi

  echo "Setting up current/${name} from ${name}"

  mkdir -p ${name}
  cd "${name}"

  cp -R "${SCRIPT_DIR}/${name}/bom.yaml" .
  cp -R "${SCRIPT_DIR}/${name}/terraform/"* .
  ln -s "${WORKSPACE_DIR}"/terraform.tfvars ./terraform.tfvars
  ln -s "${WORKSPACE_DIR}"/ssh-* .
  ln -s "${SCRIPT_DIR}/apply.sh" ./apply.sh
  ln -s "${SCRIPT_DIR}/destroy.sh" ./destroy.sh
  cd - > /dev/null
done

echo "move to ${WORKSPACE_DIR} this is where your automation is configured"
