class CodeWriter
	def initialize()
		@sam_file
		@branchIndex = 0
		@mergeIndex = 0
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
		asm_cmd = "@#{const}\n"
		asm_cmd << "D=A"<< "\n"
		asm_cmd << "@SP"<< "\n"
		asm_cmd << "A=M"<< "\n"
		asm_cmd << "M=D"<< "\n"
		asm_cmd << "@SP"<< "\n"
		asm_cmd << "M=M+1"<< "\n"
	end

	def arithmetic(cmd)
		asm_cmd = ""
		if cmd == 'add' #计算x+y
			asm_cmd << passYtoD()
			asm_cmd << "A=A-1"<< "\n"
			asm_cmd << "D=D+M"<< "\n" #D存储x+y
			asm_cmd << "M=D"<< "\n"
			asm_cmd << resetSP()
		elsif cmd == 'sub' #计算x-y
			asm_cmd << passYtoD()
			asm_cmd << "A=A-1"<< "\n"
			asm_cmd << "D=M-D"<< "\n" #D存储x-y
			asm_cmd << "M=D"<< "\n"
			asm_cmd << resetSP()
		elsif cmd == 'neg' #-y
			asm_cmd << passYtoD()
			asm_cmd << "M=-D"<< "\n" #M=-D
			asm_cmd << resetSP()
		elsif cmd == 'eq' #判断相等
			asm_cmd << passYtoD()
			asm_cmd << compare("JEQ")
			asm_cmd << resetSP()
		elsif cmd == 'gt' #判断大于
			asm_cmd << passYtoD()
			asm_cmd << compare("JGT")
			asm_cmd << resetSP()
		elsif cmd == 'lt' #判断小于
			asm_cmd << passYtoD()
			asm_cmd << compare("JLT")
			asm_cmd << resetSP()
		elsif cmd == 'and'
			asm_cmd << passYtoD()
			asm_cmd << "A=A-1"<< "\n"
			asm_cmd << "D=D&M"<< "\n" #D存储x&y
			asm_cmd << "M=D"<< "\n"
			asm_cmd << resetSP()
		elsif cmd == 'or'
			asm_cmd << passYtoD()
			asm_cmd << "A=A-1"<< "\n"
			asm_cmd << "D=D|M"<< "\n" #D存储x|y
			asm_cmd << "M=D"<< "\n"
			asm_cmd << resetSP()
		elsif cmd == 'not'
			asm_cmd << passYtoD()
			asm_cmd << "M=!D"<< "\n"
		end
		return asm_cmd
	end

	def passYtoD
		asm_cmd = ""
		asm_cmd << "@SP"<< "\n"
		asm_cmd << "A=M"<< "\n"
		asm_cmd << "A=A-1"<< "\n"
		asm_cmd << "D=M"<< "\n" #D存储y
		return asm_cmd
	end

	def resetSP
		asm_cmd = ""
		asm_cmd << "D=A"<< "\n"
		asm_cmd << "@SP"<< "\n"
		asm_cmd << "M=D+1"<< "\n" #SP指针重置
		return asm_cmd
	end

	def compare(cmd)
		asm_cmd = ""
		asm_cmd << "A=A-1"<< "\n"
		asm_cmd << "D=M-D"<< "\n" #D存储x-y
		asm_cmd << "@branchLabel_#{@branchIndex}"<< "\n"
		asm_cmd << "D;#{cmd}"<< "\n"
		asm_cmd << "D=0"<< "\n" #0代表false
		asm_cmd << "@mergeLabel_#{@mergeIndex}"<< "\n"
		asm_cmd << "0;JMP"<< "\n"
		asm_cmd << "(branchLabel_#{@branchIndex})"<< "\n"
		asm_cmd << "D=-1"<< "\n" #-1代表true
		asm_cmd << "(mergeLabel_#{@mergeIndex})"<< "\n"
		asm_cmd << "@SP"<< "\n"
		asm_cmd << "A=M-1"<< "\n"
		asm_cmd << "A=A-1"<< "\n"
		asm_cmd << "M=D"<< "\n"
		@branchIndex = @branchIndex + 1
		@mergeIndex = @mergeIndex + 1
		return asm_cmd
	end

	def close
		@sam_file.close()
	end
end