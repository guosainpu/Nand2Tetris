class SymbolTable
	def initialize()
		@table = {"SP"=>"000000000000000", "LCL"=>"000000000000001", "ARG"=>"000000000000010", "THIS"=>"000000000000011", "THAT"=>"000000000000100", "R0"=>"000000000000000", "R1"=>"000000000000001", "R2"=>"000000000000010", "R3"=>"000000000000011", "R4"=>"000000000000100", "R5"=>"000000000000101", "R6"=>"000000000000110", "R7"=>"000000000000111", "R8"=>"000000000001000", "R9"=>"000000000001001", "R10"=>"000000000001010", "R11"=>"000000000001011", "R12"=>"000000000001100", "R13"=>"000000000001101", "R14"=>"000000000001110", "R15"=>"000000000001111", "SCREEN"=>"100000000000000", "KBD"=>"110000000000000"}
	end

	def add_entry(entry)
		@table = @table.merge(entry)
	end

	def contains(symbol)
		return @table.include?(symbol)
	end

	def get_address(symbol)
		return @table[symbol]
	end

	def table
		return @table
	end
end

class Parser
	def initialize(file)
		@command_array = Array.new()
		self.reset()

		@command_array = file.gsub(/((?:\/\*(?:[^*]|(?:\*+[^*\/]))*\*+\/)|(?:\/\/.*))/, '').split #删除注释
		puts "source file:"
		puts @command_array
	end

	def reset
		@current_index = -1
		@current_command = ""
		@current_symbol = ""
		@curren_command_type = ""
	end

	def hasMoreCommand
		return @current_index+1 < @command_array.size
	end

	def advance
		@current_index += 1
		@current_command = @command_array[@current_index]
	end

	def commandType
		if @current_command =~ /@(.*)/
			@current_symbol = @current_command[1..@current_command.size-1]
			@curren_command_type = "A_COMMAND"
		elsif @current_command =~ /\((.*)\)/
			@current_symbol = @current_command[1..@current_command.size-2]
			@curren_command_type = "L_COMMAND"
		else
			@current_symbol = ""
			@curren_command_type = "C_COMMAND"
		return @curren_command_type
		end
	end

	def symbol
		return @current_symbol
	end

	def dest
		if @curren_command_type == "C_COMMAND" && @current_command.include?("=")
			return @current_command.split("=")[0]
		end
		return "NULL"
	end

	def comp
		if @curren_command_type == "C_COMMAND" && @current_command.include?("=")
			return @current_command.split("=")[1]
		elsif @curren_command_type == "C_COMMAND" && @current_command.include?(";")
			return @current_command.split(";")[0]
		end
		return "NULL"
	end

	def jump
		if @curren_command_type == "C_COMMAND" && @current_command.include?(";")
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

def completeBinary(binary_string)
	while binary_string.length < 15
		binary_string.insert(0,"0")
	end
	return binary_string
end

def is_number(string)
  return string !~ /\D/ 
end

# main 
file_name = ARGV[0]
hack_name = file_name.split(".")[0] + ".hack"

parser=Parser.new(File.read(file_name))
code = Code.new()
symbol_table = SymbolTable.new();
$command_line = 0

#第一次遍历源文件，构建符号表（初始化所有标签符号的值，因为标签符号可以先使用后声明，所以需要先遍历一遍；变量符号可以边生成机器代码时边初始化，因为变量符号是先声明后使用）
puts "generate symbol table:" 
while parser.hasMoreCommand()
	parser.advance()
	command_type = parser.commandType()
	command_symbol = parser.symbol()
	if command_type == "L_COMMAND"
		if !symbol_table.contains(command_symbol)
			symbol_table.add_entry({command_symbol=>completeBinary(($command_line).to_s(2))})
		end
	else
		$command_line += 1
	end
end

puts "generate code:"
#第二次遍历源文件，把汇编代码汇编成机器代码
parser.reset()
$variabel_address = 16 #变量从地址16开始连续分配
hack_file = File.new(hack_name, "w")

while parser.hasMoreCommand()
	new_command = ""
	parser.advance()
	command_type = parser.commandType()
	command_symbol = parser.symbol()

	if command_type == "A_COMMAND"
		new_command << "0"
		address_value = ""
		if is_number(command_symbol)
			address_value = completeBinary(command_symbol.to_i.to_s(2))
		elsif symbol_table.contains(command_symbol) #如果符号表已经包含符号，则直接取出符号的值
			address_value = symbol_table.get_address(command_symbol)
		else
			address_value = completeBinary($variabel_address.to_s(2)) #如果符号表不包含符号，则把符号加入到符号表，并把下一个变量地址+1
			symbol_table.add_entry({command_symbol=>address_value})
			$variabel_address += 1
		end
		new_command << address_value
	elsif command_type == "C_COMMAND"
		new_command << "111"
		dest_value = code.dest(parser.dest())
		comp_value = code.comp(parser.comp())
		jump_value = code.jump(parser.jump())
		new_command << comp_value
		new_command << dest_value
		new_command << jump_value
	elsif command_type == "L_COMMAND"
		next
	else
		new_command << "unknow command type"
	end

	new_command << "\n"
	hack_file.write(new_command)
end

