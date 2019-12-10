class Parser
	def initialize(file)
		@current_index = -1
		@current_command = ""
		@command_array = Array.new()
		@current_symbol = ""
		@curren_command_type = ""

		file.split("\n").each do |l|
			line = l.strip
			if line.length != 0 && !(line.include? "//")
				@command_array << line
			end
		end

		puts "source file:"
		puts @command_array
	end

	def hasMoreCommand
		return @current_index+1 < @command_array.size
	end

	def advance
		@current_index += 1
		@current_command = @command_array[@current_index]
		puts "current_command: #{@current_command}" 
	end

	def commandType
		if @current_command =~ /@(.*)/
			puts "commandType: A_COMMAND"
			@current_symbol = @current_command[1..@current_command.size-1]
			@curren_command_type = "A_COMMAND"
		elsif @current_command =~ /\((.*)\)/
			puts "commandType: L_COMMAND"
			@current_symbol = @current_command[2..@current_command.size-2]
			@curren_command_type = "L_COMMAND"
		else
			puts "commandType: C_COMMAND"
			@current_symbol = ""
			@curren_command_type = "C_COMMAND"

		return @curren_command_type
		end
	end

	def symbol
		puts "symbol: #{@current_symbol}"
		return @current_symbol
	end

	def dest
		if @curren_command_type == "C_COMMAND" && @current_command.include?("=")
			puts "dest:#{@current_command.split("=")[0]}"
			return @current_command.split("=")[0]
		end
		return "NULL"
	end

	def comp
		if @curren_command_type == "C_COMMAND" && @current_command.include?("=")
			puts "comp:#{@current_command.split("=")[1]}"
			return @current_command.split("=")[1]
		elsif @curren_command_type == "C_COMMAND" && @current_command.include?(";")
			puts "comp:#{@current_command.split(";")[0]}"
			return @current_command.split(";")[0]
		end
		return "NULL"
	end

	def jump
		if @curren_command_type == "C_COMMAND" && @current_command.include?(";")
			puts "jump:#{@current_command.split(";")[1]}"
			return @current_command.split(";")[1]
		end
		return "NULL"
	end
end

class Code
	def initialize()
		@dest_dic = {"NULL"=>"000", "M"=>"001", "D"=>"010", "MD"=>"011", "A"=>"100", "AM"=>"101", "AD"=>"110", "AMD"=>"111"}
		@comp_dic = {"0"=>"0101010", "1"=>"0111111", "-1"=>"0111010", "D"=>"0001100", "A"=>"0110000", "M"=>"1110000", "!D"=>"0001101", "!A"=>"0110001", "!M"=>"1110001", "-D"=>"0001111", "-A"=>"0110011", "-M"=>"1110011", "D+1"=>"0011111", "A+1"=>"0110111", "M+1"=>"1110111", "D-1"=>"0001110", "A-1"=>"0110010", "M-1"=>"1110010", "D+A"=>"0000010", "D+M"=>"1000010", "D-A"=>"0010011", "D-M"=>"1010011", "A-D"=>"0000111", "M-D"=>"1000111", "D&A"=>"0000000", "D&M"=>"1000000", "D|A"=>"0010101", "D|M"=>"1010101"}
		@jump_dic = {"NULL"=>"000", "JGT"=>"001", "JEQ"=>"010", "JGE"=>"011", "JLT"=>"100", "JNE"=>"101", "JLE"=>"110", "JMP"=>"111"}
	end
	
	def dest(mnemonic)
		return @dest_dic[mnemonic]
	end

	def comp(mnemonic)
		return @comp_dic[mnemonic]
	end

	def jump(mnemonic)
		return @jump_dic[mnemonic]
	end
end

# main 
file_name = ARGV[0]
hack_name = file_name.split(".")[0] + ".hack"

parser=Parser.new(File.read(file_name))
code = Code.new()
	
puts

# puts "prase file:"
# while parser.hasMoreCommand()
# 	parser.advance()
# 	parser.commandType()
# 	parser.symbol()
# 	parser.dest()
# 	parser.comp()
# 	parser.jump()
# end

def completeBinary(binary_string)
	while binary_string.length < 15
		binary_string.insert(0,"0")
	end
	return binary_string
end

puts "generate code:"
hack_file = File.new(hack_name, "w")
while parser.hasMoreCommand()
	new_command = ""
	parser.advance()
	command_type = parser.commandType()
	command_symbol = parser.symbol()

	puts command_type
	puts command_symbol

	if command_type == "A_COMMAND"
		new_command << "0"
		address_value = completeBinary(command_symbol.to_i.to_s(2))
		puts "address_value: #{address_value}"
		new_command << address_value
	elsif command_type == "C_COMMAND"
		new_command << "111"
		dest_value = code.dest(parser.dest())
		comp_value = code.comp(parser.comp())
		jump_value = code.jump(parser.jump())
		puts "comp_value: #{comp_value}"
		puts "dest_value: #{dest_value}"
		puts "jump_value: #{jump_value}"
		new_command << comp_value
		new_command << dest_value
		new_command << jump_value
	else
		new_command << "unknow command type"
	end

	new_command << "\n"
	puts new_command
	hack_file.write(new_command)
end

