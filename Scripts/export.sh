#!/bin/sh
export
chmod +x ${WORKSPACE}/Scripts/archive.swift
${WORKSPACE}/Scripts/archive.swift ${EXPORT_METHOD} "${TEAM_ID}" "${WORKSPACE}/Build/" "${WORKSPACE}" "${PROVISIONING_PROFILE_NAME}"
mv ${WORKSPACE}/*.ipa "${WORKSPACE}/${JOB_NAME}_${SHORT_VERSION}_${VERSION}_${BUILD_ID}.ipa"
cd ${WORKSPACE}/Build/Release-iphoneos
zip -r ../../${JOB_NAME}_${SHORT_VERSION}_${VERSION}_${BUILD_ID}-dSYM.zip *.dSYM
