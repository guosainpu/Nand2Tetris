require_relative 'Parser'
require_relative 'CodeWriter' 

# main 
file_name = ARGV[0]
sam_name = file_name.split(".")[0] + ".asm"

parser=Parser.new(File.read(file_name))
codeWriter = CodeWriter.new()
codeWriter.setFileName(sam_name)

puts "generate code:"
parser.reset()
while parser.hasMoreCommands()
	new_command = ""
	parser.advance()
	command_type = parser.commandType()
	arg1 = parser.arg1()
	arg2 = parser.arg2()

	puts command_type
	puts arg1
	puts arg2

	if command_type == "C_ARITHMETIC"
		codeWriter.writeArithmetic(arg1)
	elsif command_type == "C_PUSH" || command_type == "C_POP" 
		codeWriter.writePushPop(command_type, arg1, arg2)
	elsif command_type == "C_LABEL"
		codeWriter.writeLabel(arg1)
	elsif command_type == "C_GOTO"
		codeWriter.writeGoto(arg1)
	elsif command_type == "C_IF"
		codeWriter.writeIf(arg1)
	elsif command_type == "C_FUNCTION"
		codeWriter.writeFunction(arg1, arg2)
	elsif command_type == "C_RETURN"
		codeWriter.writeReturn()
	elsif command_type == "C_CALL"
		codeWriter.writeCall(arg1, arg2)
	else
		new_command << "unknow command type"
	end
end

