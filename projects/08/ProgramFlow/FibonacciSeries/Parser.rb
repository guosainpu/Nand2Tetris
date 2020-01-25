class Parser
	def initialize(file)
		@current_index = -1
		@current_command = ""
		@command_array = Array.new()
		@current_symbol = ""
		@curren_command_type = ""

		file.split("\n").each do |l|
			line = l.strip
			if  (line.include? "//")
				line = line.split("//")[0]
			end
			if line.length != 0 && !(line.include? "//")
				@command_array << line
			end
		end

		puts "source file:"
		puts @command_array
	end

	def reset
		@current_index = -1
		@current_command = ""
		@current_symbol = ""
		@curren_command_type = ""
	end

	def hasMoreCommands
		return @current_index+1 < @command_array.size
	end

	def advance
		@current_index += 1
		@current_command = @command_array[@current_index]
		puts "current_command: #{@current_command}" 
	end

	def commandType
		if @current_command =~ /push(.*)/
			puts "commandType: C_PUSH"
			@curren_command_type = "C_PUSH"
		elsif @current_command =~ /pop(.*)/
			puts "commandType: C_POP"
			@curren_command_type = "C_POP"
		elsif @current_command =~ /label(.*)/
			puts "commandType: C_LABEL"
			@curren_command_type = "C_LABEL"
		elsif @current_command =~ /if-goto(.*)/
			puts "commandType: C_IF"
			@curren_command_type = "C_IF"
		elsif @current_command =~ /goto(.*)/
			puts "commandType: C_GOTO"
			@curren_command_type = "C_GOTO"
		elsif @current_command =~ /function(.*)/
			puts "commandType: C_FUNCTINO"
			@curren_command_type = "C_FUNCTINO"
		elsif @current_command =~ /return(.*)/
			puts "commandType: C_RETURN"
			@curren_command_type = "C_RETURN"
		elsif @current_command =~ /call(.*)/
			puts "commandType: C_CALL"
			@curren_command_type = "C_CALL"
		else
			puts "commandType: C_ARITHMETIC"
			@curren_command_type = "C_ARITHMETIC"
		end
		return @curren_command_type
	end

	def arg1
		tokenArray = @current_command.gsub(/\s+/m, ' ').strip.split(" ")
		if tokenArray.length > 1
			return tokenArray[1]
		else
			return tokenArray[0]
		end
	end

	def arg2
		tokenArray = @current_command.gsub(/\s+/m, ' ').strip.split(" ")
		if tokenArray.length > 2
			return tokenArray[2]
		else
			return ''
		end
	end
end