#!/usr/bin/swift

import Foundation

let arguments = CommandLine.arguments
var archivePath: String = ""
var exportPath: String = ""
var provisioningProfileName = ""
var teamID = ""
var exportMethod = ""

if arguments.count != 6 {
	print("Invoke with: \(arguments[0]) exportMethod teamID pathToxcarchive pathForExport nameOfProvisioningProfile")
	print("\(arguments)")
	exit(1)
}

exportMethod = arguments[1]
teamID = arguments[2]
archivePath = arguments[3]
exportPath = arguments[4]
provisioningProfileName = arguments[5]

if let archives = try? FileManager.default.contentsOfDirectory(atPath: archivePath) {
	let matches = archives.filter {$0.lowercased().hasSuffix(".xcarchive")}
	if let archiveName = matches.first {
		archivePath += "/" + archiveName
	}
}

let infoPlist = archivePath + "/Info.plist"
var bundleIdentifier: String?
if let inputStream = InputStream(fileAtPath: infoPlist) {
	inputStream.open()
	if let plist = try? PropertyListSerialization.propertyList(with: inputStream, options: [], format: nil) {
		if let props = plist as? [String: Any] {
			if let appProps = props["ApplicationProperties"] as? [String: String] {
				bundleIdentifier = appProps["CFBundleIdentifier"]
			}
		}
	}
	inputStream.close()
}

try? FileManager.default.createDirectory(atPath: exportPath, withIntermediateDirectories: true, attributes: nil)

print("\(arguments)")
var dict: = [String: Any]()
dict["compileBitcode"] = false
if let bundleIdentifier = bundleIdentifier {
	dict["provisioningProfiles"] = [bundleIdentifier: provisioningProfileName]
}
dict["method"] = exportMethod
dict["teamID"] = teamID
let optionsFilePath = exportPath + "/options.plist"
if let stream = OutputStream(toFileAtPath: optionsFilePath, append: false) {
	stream.open()
	PropertyListSerialization.writePropertyList(dict, to: stream, format: .xml, options: 0, error: nil)
	stream.close()

    let task = Process()
	task.launchPath = "/usr/bin/xcodebuild"
	task.arguments = ["-exportArchive", "-archivePath", archivePath, "-exportPath", exportPath, "-exportOptionsPlist", optionsFilePath]
	task.launch()
	task.waitUntilExit()
}
