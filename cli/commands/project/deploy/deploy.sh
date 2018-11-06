
set -eu
cd "$(dirname "$0")"

BCM_PROJECT_NAME=
BCM_CLUSTER_NAME=

for i in "$@"
do
case $i in
    --project-name=*)
    BCM_PROJECT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --cluster-name=*)
    BCM_CLUSTER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


if [[ -z $(bcm project list | grep "$BCM_PROJECT_NAME") ]]; then
    echo "BCM project '$BCM_PROJECT_NAME' not found. Can't deploy."
    exit
fi

if [[ -z $(bcm cluster list | grep "$BCM_CLUSTER_NAME") ]]; then
    echo "BCM cluster '$BCM_CLUSTER_NAME' not found. Can't deploy project to it."
    exit
fi

