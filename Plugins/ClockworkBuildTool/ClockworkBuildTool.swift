//
//  ClockworkBuildTool.swift
//
//
//  Created by Dr. Brandon Wiley on 1/5/23.
//

import Foundation
import PackagePlugin

@main
struct ClockworkBuildTool: BuildToolPlugin
{
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command]
    {
        let tool = try context.tool(named: "ClockworkCommandLine")

        guard let target = target as? SwiftSourceModuleTarget else
        {
            throw ClockworkBuildToolError.wrongTargetType
        }

        let commands: [Command] = target.sourceFiles
        .map { $0.path }
        .compactMap
        {
            let filename = $0
            let outputPath = context.pluginWorkDirectory

            return .prebuildCommand(
                displayName: "Clockwork Messages \(filename)",
                executable: tool.path,
                arguments: [],
                outputFilesDirectory: outputPath
            )
        }


        return commands
    }
}

public enum ClockworkBuildToolError: Error
{
    case wrongTargetType
}
