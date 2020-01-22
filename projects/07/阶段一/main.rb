require 'Parser'
require 'CodeWriter' 

# main 
file_name = ARGV[0]
sam_name = file_name.split(".")[0] + ".sam"

parser=Parser.new(File.read(file_name))
codeWriter = CodeWriter.new()
codeWriter.setFileName(sam_name)
$command_line = 0
	
puts "generate symbol table:"
while parser.hasMoreCommand()
	parser.advance()
	command_type = parser.commandType()
	command_symbol = parser.symbol()
	if command_type == "L_COMMAND"
		if !symbol_table.contains(command_symbol)
			puts "+++++++++#{command_symbol}:#{$command_line}"
			symbol_table.add_entry({command_symbol=>completeBinary(($command_line).to_s(2))})
		end
	else
		$command_line += 1
	end
end

puts "generate code:"
parser.reset()
while parser.hasMoreCommands()
	new_command = ""
	parser.advance()
	command_type = parser.commandType()
	arg1 = parser.arg1()
	arg2 = parser.arg1()

	puts command_type
	puts arg1
	puts arg2

	if command_type == "C_ARITHMETIC"
		codeWriter.writeArithmetic(arg1)
	elsif command_type == "C_PUSH" || command_type == "C_POP" 
		codeWriter.writePushPop(command_type, arg1, arg2)
	elsif command_type == "L_COMMAND"
		next
	else
		new_command << "unknow command type"
	end
end

