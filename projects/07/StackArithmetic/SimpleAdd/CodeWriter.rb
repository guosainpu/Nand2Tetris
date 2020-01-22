class CodeWriter
	def initialize()
		@sam_file
	end

	def setFileName(fileName)
		@sam_file = File.new(fileName, "w")
	end

	def writeArithmetic(command) #输出相应的算数操作代码
		sam_command = ''
		sam_command = arithmetic(command)
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
		sam_cmd = "@#{const}\n"
		sam_cmd << "D=A"<< "\n"
		sam_cmd << "@SP"<< "\n"
		sam_cmd << "A=M"<< "\n"
		sam_cmd << "M=D"<< "\n"
		sam_cmd << "@SP"<< "\n"
		sam_cmd << "M=M+1"<< "\n"
	end

	def arithmetic(cmd)
		sam_cmd = ""
		if cmd == 'add' #计算x+y
			sam_cmd << "@SP"<< "\n"
			sam_cmd << "A=M"<< "\n"
			sam_cmd << "A=A-1"<< "\n"
			sam_cmd << "D=M"<< "\n" #D存储y
			sam_cmd << "A=A-1"<< "\n"
			sam_cmd << "D=D+M"<< "\n" #D存储x+y
			sam_cmd << "M=D"<< "\n"
			sam_cmd << "D=A"<< "\n"
			sam_cmd << "@SP"<< "\n"
			sam_cmd << "M=D+1"<< "\n" #SP指针重置
		end
		return sam_cmd
	end

	def close
		@sam_file.close()
	end
end