#!/usr/bin/swift
import Foundation
import Cocoa

func shell(command: String, currentDirectoryPath: String) -> String {
    print("Running: \(command)")
    let task = Process()
    let pipe = Pipe()

    var arguments: [String] = []
    let components = command.components(separatedBy: " ")
    for component in components {
        if task.launchPath == nil {
            task.launchPath = component
        } else {
            arguments.append(component)
        }
    }

    task.arguments = arguments
    task.standardOutput = pipe.fileHandleForWriting
    let emptyString = "*"
    if let data = emptyString.data(using: String.Encoding.utf8) {
        pipe.fileHandleForWriting.write(data)
    }

    task.currentDirectoryPath = currentDirectoryPath
    task.launch()
    task.waitUntilExit()
    let output = pipe.fileHandleForReading.availableData
    if output.count > 1 {
        var outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
        if outputString.characters.count > 1 {
            let startIndex = outputString.index(outputString.startIndex, offsetBy: 1)
            outputString = String(outputString[startIndex...])
        }
        return outputString
    } else {
        return ""
    }
}

func extract(from str: String) -> String {
    if let leftParen = str.range(of: "("), let rightParen = str.range(of: ")") {
        let startIndex = str.index(leftParen.lowerBound, offsetBy: 1)
        let newStr = String(str [startIndex..<rightParen.lowerBound])
        return newStr
    }

    return str
}

func replaceString(from str: String, with string: String) -> String {
    if let leftParen = str.range(of: "("), let rightParen = str.range(of: ")") {
        let startIndex = str.index(leftParen.lowerBound, offsetBy: 1)
        let range = startIndex..<rightParen.lowerBound
        var newStr = str
        newStr.replaceSubrange(range, with: string)
        return newStr
    }

    return str
}

func tagAndRelease() {
    let git = "/usr/bin/git"
    let fileManager = FileManager()
    var projectName: String?
    var version = ""
    var buildNumber = ""
    var versionTag = ""
    let currentPath = getCurrentDirectoryPath()
    if let currentURL = URL(string: currentPath) {
        let parentURL = currentURL.deletingLastPathComponent()
        // Find the xcodeproj
        if let contents = try? fileManager.contentsOfDirectory(atPath: parentURL.path) {
            let projects: [String] = contents.flatMap {
                if let fileURL = URL(string:parentURL.path + "/" + $0) {
                    if fileURL.pathExtension.lowercased() == "xcodeproj" {
                        return fileURL.deletingPathExtension().lastPathComponent
                    }
                }

                return nil
            }

            projectName = projects.first
        }

        let definesPath = URL(fileURLWithPath:parentURL.appendingPathComponent("Defines.h").path)
        var newLines: [String] = []
        if let defines = try? String(contentsOf: definesPath) {
            let lines = defines.components(separatedBy: "\n")

            for line in lines {
                if line.range(of: "CF_BUNDLE_VERSION") != nil {
                    if let build = Int(extract(from: line)) {
                        let newBuild = build + 1
                        buildNumber = String(newBuild)
                        newLines.append(replaceString(from:line, with:String(newBuild)))
                    }
                } else {
                    newLines.append(line)
                }
            }

            // Run through again and we'll replace the APP_VERSION_NUMBER
            for (index, line) in newLines.enumerated() {
                if line.range(of: "APP_VERSION_NUMBER") != nil {
                    let shortVersion = extract(from: line)
                    let components = shortVersion.components(separatedBy: ".")
                    if components.count == 3 {
                        version = "\(components[0]).\(components[1]).\(buildNumber)"
                        let result = replaceString(from: line, with: version)
                        newLines[index] = result
                    }

                }
            }

            // Increase the CF_BUNDLE_VERSION

            let newFile = newLines.joined(separator: "\n")
            try? newFile.write(to: definesPath, atomically: true, encoding: String.Encoding.utf8)

        }

        print("Current path \(currentPath)")
        print("Current parentURL \(parentURL)")
        print("Version: \(version)")
        print("Build Number: \(buildNumber)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMddHHmmss"

        // Tag should be ProjectName-Version-BuildNumber-Date

        if let projectName = projectName {
            versionTag = projectName + "-" + version + "-" + buildNumber + "-" + dateFormatter.string(from: Date())
        }

        print("Version tag: \(versionTag)")

        let tags = shell(command: "\(git) tag -l", currentDirectoryPath: parentURL.path)
        let tagArray: [String] = tags.components(separatedBy: "\n").flatMap {
            return $0.isEmpty ? nil : $0
        }

        let sortedTagArray = tagArray.sorted {
            if let dateStr1 = $0.components(separatedBy: "-").last, let dateStr2 = $1.components(separatedBy: "-").last {
                return dateStr1 > dateStr2
            }
            return $1 < $0
        }
        var recentTag = ""

        if sortedTagArray.count > 0 {
            recentTag = sortedTagArray.first ?? ""
        }

        print("Recent tag: \(recentTag)")

        // Read the current release notes
        let allNotesURL = URL(fileURLWithPath:parentURL.appendingPathComponent("ReleaseNotes.txt").path)
        var allReleaseNotes = try? String(contentsOf: allNotesURL)

        if recentTag.isEmpty == false {
            // Grab the commits since the recent tag
            let commitString = shell(command: "\(git) log --pretty=format:%s-(%h) \(recentTag)..HEAD", currentDirectoryPath: parentURL.path)
            let commitArray: [String] = commitString.components(separatedBy: "\n").flatMap {
                return $0.isEmpty ? nil : $0
            }

            var releaseNotes = "Release Notes for \(projectName!) \(version) - Build \(buildNumber)\n\n"

            releaseNotes += "Changes from \(recentTag)\n"
            releaseNotes += "----------------------------------------------\n"

            for commit in commitArray {
                releaseNotes += "\(commit)\n"
            }

            let releaseURL = URL(fileURLWithPath:parentURL.appendingPathComponent("CurrentRelease.txt").path)
            try? releaseNotes.write(to: releaseURL, atomically: true, encoding: String.Encoding.utf8)

            if allReleaseNotes == nil {
                allReleaseNotes = releaseNotes
            } else {
                allReleaseNotes! = releaseNotes + "\n\n=================================================================================================\n\n" + allReleaseNotes!
            }
            try? allReleaseNotes!.write(to: allNotesURL, atomically: true, encoding: String.Encoding.utf8)
        }

        // git commit all
        _ = shell(command: "\(git) commit -a -m Release", currentDirectoryPath: parentURL.path)

        // git push
        _ = shell(command: "\(git) tag -a \(versionTag) -m Tagged", currentDirectoryPath: parentURL.path)

        //    _ = shell(command: "\(git) push origin", currentDirectoryPath: parentURL.path)
        // Push the tag

        //    _ = shell(command: "\(git) push origin \(versionTag)", currentDirectoryPath: parentURL.path)

    }
}

func getCurrentDirectoryPath() -> String {
    if let executePath = CommandLine.arguments.first {
        let fileManager = FileManager()
        var currentPath = fileManager.currentDirectoryPath
        var components = executePath.components(separatedBy: "/")
        if components.first == "." {
            components.removeFirst()
        }

        components.removeLast()
        if components.count > 0 {
            if let currentURL = URL(string: currentPath) {
                var newURL = currentURL
                for path in components {
                    newURL = newURL.appendingPathComponent(path)
                }

                currentPath = newURL.path
            }
        }

        return currentPath
    }
    return ""
}

tagAndRelease()
