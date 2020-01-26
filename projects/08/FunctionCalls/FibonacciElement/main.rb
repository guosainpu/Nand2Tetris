require_relative 'Parser'
require_relative 'CodeWriter' 

def translateCode(parser, codeWriter)
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
		puts ""

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
end

# main 
file_name_or_dir_name = ARGV[0]

if File.file?(file_name_or_dir_name)
	# 翻译单个文件
	file_name = file_name_or_dir_name
	parser=Parser.new(File.read(file_name))
	asm_file = File.new(file_name.split(".")[0] + ".asm", "w")
	codeWriter = CodeWriter.new()
	codeWriter.setFile(asm_file)
	translateCode(parser, codeWriter)
elsif File.directory?(file_name_or_dir_name)
	# 翻译多文件+引导程序
	dirname = File.basename(Dir.getwd)
	asm_file = File.new("#{dirname}.asm", "w")
	codeWriter = CodeWriter.new()
	codeWriter.setFile(asm_file)
	codeWriter.writeSysInit()
	Dir.foreach(file_name_or_dir_name) do |filename|
  		if filename.split(".")[1] == "vm"
  			puts filename
  			parser=Parser.new(File.read(filename))
  			translateCode(parser, codeWriter)
  		end
	end
end 



