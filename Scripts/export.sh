#!/bin/sh
export
chmod +x ${WORKSPACE}/Scripts/archive.swift
${WORKSPACE}/Scripts/archive.swift ${EXPORT_METHOD} "${TEAM_ID}" "${WORKSPACE}/Build/" "${WORKSPACE}" "${PROVISIONING_PROFILE_NAME}"
mv ${WORKSPACE}/*.ipa "${WORKSPACE}/${APP_NAME}-${BRANCH}-${CONFIGURATION}-${MAJOR_MINOR_VERSION}-${SHORT_VERSION}-${FULL_BUILD_DATE}.ipa"
cd ${WORKSPACE}/Build/Release-iphoneos
zip -r ../../${APP_NAME}-${BRANCH}-Release-${MAJOR_MINOR_VERSION}-${SHORT_VERSION}-${FULL_BUILD_DATE}-dSYM.zip *.dSYM
