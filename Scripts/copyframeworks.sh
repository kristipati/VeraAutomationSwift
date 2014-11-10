#!/bin/sh
echo "Copying Frameworks..."
cd ${TARGET_BUILD_DIR}
FRAMEWORKS_PATH="${TARGET_BUILD_DIR}/${EXECUTABLE_FOLDER_PATH}/Frameworks"
mkdir -p "${FRAMEWORKS_PATH}"
cp -r "${TARGET_BUILD_DIR}/Alamofire.framework" "${FRAMEWORKS_PATH}"
cp -r "${TARGET_BUILD_DIR}/Vera.framework" "${FRAMEWORKS_PATH}"
