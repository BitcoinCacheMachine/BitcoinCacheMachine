
docker kill bcmtrezoragent

sleep 2

docker system prune -f

sleep 2

docker build -t bcmtrezor:latest .

source $BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh
source $BCM_LOCAL_GIT_REPO/dev_machine/trezor/export_usb_path.sh
export COMMAND=git
export OPERATION=commit
export FILE_PATH=~/git/github/bcm
export BCM_CERT_DIR=$GNUPGHOME
export BCM_GIT_COMMIT_MESSAGE='Added trezor integration to dev_machine.'
export BCM_PROJECT_CERTIFICATE_EMAIL='derek@farscapian.com'
export BCM_GIT_CLIENT_USERNAME='farscapian'

echo "BCM_CERT_DIR: '$BCM_CERT_DIR'"
echo "FILE_PATH: '$FILE_PATH'"
echo "TREZOR_USB_PATH: '$TREZOR_USB_PATH'"
docker run -d --name bcmtrezoragent \
    -v $BCM_CERT_DIR:/root/.gnupg/trezor \
    -v $FILE_PATH:/gitrepo \
    --device="$TREZOR_USB_PATH" \
    bcmtrezor:latest

sleep 2

echo "BCM_PROJECT_CERTIFICATE_EMAIL: '$BCM_PROJECT_CERTIFICATE_EMAIL'"
echo "BCM_GIT_COMMIT_MESSAGE: '$BCM_GIT_COMMIT_MESSAGE'"
echo "BCM_GIT_CLIENT_USERNAME: '$BCM_GIT_CLIENT_USERNAME'"

docker exec -it -e BCM_PROJECT_CERTIFICATE_EMAIL="$BCM_PROJECT_CERTIFICATE_EMAIL" \
    -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
    -e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
    -e BCM_GIT_AUTO_PUSH="true" \
    bcmtrezoragent /commit_sign_git_repo.sh

