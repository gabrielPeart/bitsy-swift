import Foundation

struct ArgumentConfig {
    let reader: CodeReader
    let generator: CodeGenerator

    init(version: String) {
        let versionArg = CounterOption(shortFlag: "v", longFlag: "version", helpMessage: "Print the version of bitsy-swift")
        let help = CounterOption(shortFlag: "h", longFlag: "help", helpMessage: "Display bitsy-swift usage")
        let cliInput = CounterOption(shortFlag: "c", longFlag:"read-cli", helpMessage: "Read Bitsy code from the command line, terminated by a '.'")
        let outputPath = StringOption(shortFlag: "o", longFlag:"output", helpMessage: "Specify a name for the binary output")
        let cliOutput = CounterOption(shortFlag: "e", longFlag: "emit-cli", helpMessage: "Emit intermediate compilation to command line")
        let runDelete = CounterOption(shortFlag: "r", longFlag: "run-delete", helpMessage: "Immediately run and delete the compiled binary")
        let retainIntermediate = CounterOption(shortFlag: "i", longFlag: "retain-intermediate", helpMessage: "Retain results of intermediate representation")

        let cli = CommandLine()
        cli.addOptions(versionArg, help, cliInput, outputPath, cliOutput, runDelete, retainIntermediate)

        do {
            try cli.parse()
        } catch {
            cli.printUsage(error)
            exit(EX_USAGE)
        }

        if help.value > 0 {
            cli.printUsage()
            exit(EX_OK)
        }

        let shouldRunDelete = runDelete.value > 0
        let shouldRetain = retainIntermediate.value > 0

        ArgumentConfig.check(argument: versionArg, version: version)
        reader = ArgumentConfig.reader(freeArgs: cli.unparsedArguments, cliInput: cliInput)
        let emitter = ArgumentConfig.emitter(outputPath: outputPath, cliOutput: cliOutput, retain: shouldRetain, runDelete: shouldRunDelete)
        generator = SwiftGenerator(emitter: emitter)
    }
}

private extension ArgumentConfig {
    static func check(argument arg:CounterOption, version: String) {
        if arg.value > 0 {
            print(version)
            exit(EX_OK)
        }
    }

    static func reader(freeArgs freeArgs: [String], cliInput: CounterOption) -> CodeReader {
        if cliInput.value > 0 {
            return CmdLineReader()
        }

        guard let filePath = freeArgs.first where filePath.hasSuffix("bitsy") else {
            print("Please provide a valid .bitsy file for compilation; run -h for more info")
            exit(EX_NOINPUT)
        }

        return FileReader(filePath: filePath)
    }

    static func emitter(outputPath output:StringOption, cliOutput: CounterOption, retain: Bool, runDelete: Bool) -> CodeEmitter {
        if cliOutput.value > 0 {
            return CmdLineEmitter()
        }

        if let path = output.value {
            return FileEmitter(filePath: path, retainIntermediate: retain, runDeleteBinary: runDelete)
        } else {
            return FileEmitter(filePath: "b.out", retainIntermediate: retain, runDeleteBinary: runDelete)
        }
    }
}
