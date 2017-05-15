#!/bin/sh
if which license-plist >/dev/null; then
cd ..
license-plist --output-path Automation/Resources/Settings.bundle
fi