shortversionnumber=`/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}`
echo "SHORT_VERSION=${shortversionnumber}" > "${SRCROOT}/JenkinsProperties"

bundleversionnumber=`/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}`
shortversionnumber=`echo $shortversionnumber '('$bundleversionnumber')'`

echo ${shortversionnumber}

src_file="${SRCROOT}/Piccee/Resources/Settings.bundle/Root.plist"

dest_file="${BUILT_PRODUCTS_DIR}""/""${UNLOCALIZED_RESOURCES_FOLDER_PATH}""/Settings.bundle/Root.plist"
echo $dest_file

/usr/libexec/PlistBuddy -c "delete :PreferenceSpecifiers" "$dest_file"
/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers array" "$dest_file"
/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:0:Title string About" "$dest_file"
/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:0:Type string PSGroupSpecifier" "$dest_file"

/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:1:Key string VersionKey" "$dest_file"
/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:1:DefaultValue string ${shortversionnumber}" "$dest_file"
/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:1:Title string Version" "$dest_file"
/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:1:Type string PSTitleValueSpecifier" "$dest_file"

/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:2:File string Acknowledgements" "$dest_file"
/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:2:Title string Acknowledgements" "$dest_file"
/usr/libexec/PlistBuddy -c "add :PreferenceSpecifiers:2:Type string PSChildPaneSpecifier" "$dest_file"
