
class CodeWriter
	def initialize(file)
		@sam_file
	end

	def setFileName(fileName)
		@sam_file = File.new(fileName, "w")
	end

	def writeArithmetic(command) #输出相应的算数操作代码
		sam_command = ''

		if sam_command.length > 0
			@sam_file.write(sam_command)
		end	
	end

	def writePushPop(command, segment, index) #输出相应的push,pop操作代码
		sam_command = ''
		if command == 'C_PUSH' && segment =='constant' #实现简单的push const
			sam_command << pushConstant(index)
		#elsif
		end

		if sam_command.length > 0
			@sam_file.write(sam_command)
		end	
	end

	def pushConstant(const) #实现简单的push const
		sam_cmd = "@"+const+"\n"
		sam_cmd << "D=A"
		sam_cmd << "@SP"
		sam_cmd << "A=M"
		sam_cmd << "M=D"
		sam_cmd << "@SP"
		sam_cmd << "M=M+1"
		sam_cmd << "\n"
	end

	def close
		@sam_file.close()
	end
end