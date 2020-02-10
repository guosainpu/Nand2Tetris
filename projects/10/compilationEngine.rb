require_relative 'JackTokenizer'

def compilationEngine
	def initialize(tokenizer, outputfile)
		@tokenizer = tokenizer
		@outputfile = outputfile

		self.compileClass()
	end

	#compile method
	#编译整个类
	def compileClass
		@outputfile.write("<class>\n")
		self.writeKeyword() #class
		self.writeIndentifier() #className
		self.compileClassVarDec() #classVarDec*
		self.compileSubroutine() #subroutine*
		self.writeSymbol() #{
		self.writeSymbol() #}
		@outputfile.write("<class>\n")
	end

	#编译静态变量或成员变量的声明

	def compileClassVarDec
		
	end

	def compileSubroutine
		
	end
	

	#helpers
	def writeKeyword()
		@tokenizer.advance()
		if @tokenizer.tokenType() != "KEYWORD"
			self.throwError("不是KEYWORD")
		end
		@outputfile.write("<keyword> #{@tokenizer.keyword()} </keyword>\n")
	end

	def writeIndentifier()
		@tokenizer.advance()
		if @tokenizer.tokenType() != "IDENTIFIER"
			self.throwError("不是IDENTIFIER")
		end
		@outputfile.write("<identifier> #{@tokenizer.identifier()} </identifier>\n")
	end

	def writeSymbol()
		@tokenizer.advance()
		if @tokenizer.tokenType() != "SYMBOL"
			self.throwError("不是SYMBOL")
		end
		@outputfile.write("<symbol> #{@tokenizer.symbol()} </symbol>\n")
	end

	def writeNumber()
		@tokenizer.advance()
		if @tokenizer.tokenType() != "INT-CONST"
			self.throwError("不是INT-CONST")
		end
		@outputfile.write("<integerConstant> #{@tokenizer.iniVal()} </integerConstant>\n")
	end

	def writeString()
		@tokenizer.advance()
		if @tokenizer.tokenType() != "STRING-CONST"
			self.throwError("不是STRING-CONST")
		end
		@outputfile.write("<stringConstant> #{@tokenizer.stringValue()} </stringConstant>\n")
	end

	def throwError(messge)
		raise Exception.new(messge)
	end
end