
class VMWriter
	def initialize(outputFile)
		@outputFile = outputFile
	end

	def writePush(segement, index)
		self.writeCmd("push", segement, index)
	end

	def writePop(segement, index)
		self.writeCmd("pop", segement, index)
	end

	def writeArithmetic(op)
        self.writeCmd(op)
    end
        
    def writeLabel(label)
        self.writeCmd("label", label)
    end
        
    def writeGoto(label)
        self.writeCmd("goto", label)
    end
        
    def writeIf(label)
        self.writeCmd("if-goto", label)
    end
        
    def writeCall(name, numArgs)
        self.writeCmd("call", name, numArgs)
    end
        
    def writeFunction(name, numLocals)
        self.writeCmd("function", name, numLocals)
    end
        
    def writeReturn()
        self.writeCmd("return")
    end

    #writeHelper

    def writePushNumber(number)
    	self.writePush("constant", number)
    end

	def writeCmd(cmd, arg1=nil, arg2=nil)
		cmd = cmd.split("\n")[0]
		if arg1
			cmd << " #{arg1}"
		end
		if arg2
			cmd << " #{arg2}"
		end
		cmd << "\n"
		@outputFile.write(cmd)
	end

	def close
		@outputFile.close()
	end
end



