#!/bin/sh
echo "Copying Frameworks..."
cd ${TARGET_BUILD_DIR}
echo ${TARGET_BUILD_DIR}
FRAMEWORKS_PATH="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "${FRAMEWORKS_PATH}"
ls -al ${TARGET_BUILD_DIR}
cp -r "${TARGET_BUILD_DIR}/Alamofire.framework" "${FRAMEWORKS_PATH}"
cp -r "${TARGET_BUILD_DIR}/CryptoSwift.framework" "${FRAMEWORKS_PATH}"
cp -r "${TARGET_BUILD_DIR}/Vera.framework" "${FRAMEWORKS_PATH}"
