class CodeWriter
	def initialize()
		@sam_file
		@branchIndex = 0
		@mergeIndex = 0
		@table = {"constant"=>"constant", "local"=>"LCL", "argument"=>"ARG", "this"=>"THIS", "that"=>"THAT", "temp"=>"temp", "pointer"=>"pointer", "static"=>"static"}
	end

	def setFileName(fileName)
		@file_name = fileName.split(".")[0]
		@sam_file = File.new(fileName, "w")
	end

	def writeArithmetic(command) #输出相应的算数操作代码
		asm_cmd = ''
		asm_cmd = arithmetic(command)
		if asm_cmd.length > 0
			@sam_file.write(asm_cmd)
		end	
	end

	def writePushPop(command, segment, index) #输出相应的push,pop操作代码
		asm_cmd = ''
		segment = @table["#{segment}"]
		if command == 'C_PUSH' && segment =='constant' #实现简单的push const
			asm_cmd << pushConstant(index)
		elsif command == 'C_PUSH' #实现push segment存储的内容(local, argument, this, that)
			asm_cmd << passArgsAddressToA(segment, index) #A=段地址+偏移地址
			asm_cmd << "D=M"<< "\n" #段的内容寄存到D
			asm_cmd << pushDtoStack()
		elsif command == 'C_POP' #实现pop segment存储的内容(local, argument, this, that)
			asm_cmd << passArgsAddressToA(segment, index) #A=段地址+偏移地址
			asm_cmd << getStackTopToD()
			asm_cmd << "M=D"<< "\n" #pop D到相应位置
			asm_cmd << "@SP"<< "\n"
			asm_cmd << "M=M-1"<< "\n" #指针减1
		end

		if asm_cmd.length > 0
			@sam_file.write(asm_cmd)
		end	
	end

	def pushConstant(const) #实现简单的push const
		asm_cmd = "@#{const}\n"
		asm_cmd << "D=A"<< "\n"
		asm_cmd << pushDtoStack()
		return asm_cmd
	end

	def pushDtoStack
		asm_cmd = "@SP"<< "\n"
		asm_cmd << "A=M"<< "\n"
		asm_cmd << "M=D"<< "\n"
		asm_cmd << "@SP"<< "\n"
		asm_cmd << "M=M+1"<< "\n"
		return asm_cmd
	end

	def getStackTopToD
		asm_cmd = "D=A"<< "\n" 
		asm_cmd << "@R13"<< "\n"
		asm_cmd << "M=D"<< "\n" #先把A的值暂存到R13,后面在恢复
		asm_cmd << "@SP"<< "\n"
		asm_cmd << "A=M-1"<< "\n"
		asm_cmd << "D=M"<< "\n" #取出值放入D
		asm_cmd << "@R13"<< "\n"
		asm_cmd << "A=M"<< "\n" #恢复A的值
		return asm_cmd
	end

	def passArgsAddressToA(segment, index)
		asm_cmd = ''
		if  segment =="static"
			asm_cmd << "@#{@file_name}.#{index}"<< "\n" #D=index
		end

		asm_cmd << "@#{index}"<< "\n"
		asm_cmd << "D=A"<< "\n" #D=index
		if  segment == "temp"
			asm_cmd << "@R5"<< "\n"
			asm_cmd << "A=A+D"<< "\n" #A=寄存器+偏移地址
			puts "执行了#{segment}"
		elsif segment == "pointer"
			asm_cmd << "@THIS"<< "\n"
			asm_cmd << "A=A+D"<< "\n" #A=THIS+偏移地址
		else
			asm_cmd << "@#{segment}"<< "\n"
			asm_cmd << "A=M+D"<< "\n" #A=段地址+偏移地址
		end
		return asm_cmd
	end

	def pushValueToAddress(value, address)

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

	def compare(cmd) #xy大小判断
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