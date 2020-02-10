require_relative 'JackTokenizer'

class CompilationEngine

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
		token = @tokenizer.keyword()
		if @tokenizer.tokenType() != "KEYWORD"
			self.throwError("#{token} 不是KEYWORD")
		end
		@outputfile.write("<keyword> #{token} </keyword>\n")
	end

	def writeIndentifier()
		@tokenizer.advance()
		token = @tokenizer.identifier()
		if @tokenizer.tokenType() != "IDENTIFIER"
			self.throwError("#{token} 不是IDENTIFIER")
		end
		@outputfile.write("<identifier> #{token} </identifier>\n")
	end

	def writeSymbol()
		@tokenizer.advance()
		token = @tokenizer.symbol()
		if @tokenizer.tokenType() != "SYMBOL"
			self.throwError("#{token} 不是SYMBOL")
		end
		@outputfile.write("<symbol> #{token} </symbol>\n")
	end

	def writeNumber()
		@tokenizer.advance()
		token = @tokenizer.iniVal()
		if @tokenizer.tokenType() != "INT-CONST"
			self.throwError("#{token} 不是INT-CONST")
		end
		@outputfile.write("<integerConstant> #{token} </integerConstant>\n")
	end

	def writeString()
		@tokenizer.advance()
		token = @tokenizer.stringValue()
		if @tokenizer.tokenType() != "STRING-CONST"
			self.throwError("#{token} 不是STRING-CONST")
		end
		@outputfile.write("<stringConstant> #{token} </stringConstant>\n")
	end

	def throwError(messge)
		raise Exception.new(messge)
	end
end