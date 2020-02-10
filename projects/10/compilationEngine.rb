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
		@tokenizer.advance()
		self.writeKeyword() #class
		@tokenizer.advance()
		self.writeIndentifier() #className
		@tokenizer.advance()
		self.writeSymbol() #{
		self.compileClassVarDec() #classVarDec*
		self.compileSubroutine() #subroutine*
		@tokenizer.advance()
		self.writeSymbol() #}
		@outputfile.write("</class>\n")
	end

	#编译静态变量或成员变量的声明
	def compileClassVarDec
		@tokenizer.advance()
		isVar = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "static" || @tokenizer.keyword() == "field")
		while isVar
			@outputfile.write("<classVarDec>\n")
			self.writeKeyword() #(static|field)
			@tokenizer.advance()
			if @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "int" || @tokenizer.keyword() == "char" || @tokenizer.keyword() == "boolean")
				self.writeKeyword() #(basic type)
			elsif @tokenizer.tokenType == "IDENTIFIER"
				self.writeIndentifier() #(class type)
			end
			@tokenizer.advance()
			self.writeVar() #varName or varNames
			@tokenizer.advance()
			isVar = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "static" || @tokenizer.keyword() == "field")
			@outputfile.write("</classVarDec>\n")
		end
		@tokenizer.backward()
		return
	end

	def compileSubroutine
		@outputfile.write("<subroutineDec>\n")
		@outputfile.write("</subroutineDec>\n")
	end
	
	#helpers
	def writeKeyword()
		token = @tokenizer.keyword()
		if @tokenizer.tokenType() != "KEYWORD"
			self.throwError("#{token} 不是KEYWORD")
		end
		@outputfile.write("<keyword> #{token} </keyword>\n")
	end

	def writeIndentifier()
		token = @tokenizer.identifier()
		if @tokenizer.tokenType() != "IDENTIFIER"
			self.throwError("#{token} 不是IDENTIFIER")
		end
		@outputfile.write("<identifier> #{token} </identifier>\n")
	end

	def writeSymbol()
		token = @tokenizer.symbol()
		if @tokenizer.tokenType() != "SYMBOL"
			self.throwError("#{token} 不是SYMBOL")
		end
		@outputfile.write("<symbol> #{token} </symbol>\n")
	end

	def writeNumber()
		token = @tokenizer.iniVal()
		if @tokenizer.tokenType() != "INT-CONST"
			self.throwError("#{token} 不是INT-CONST")
		end
		@outputfile.write("<integerConstant> #{token} </integerConstant>\n")
	end

	def writeString()
		token = @tokenizer.stringValue()
		if @tokenizer.tokenType() != "STRING-CONST"
			self.throwError("#{token} 不是STRING-CONST")
		end
		@outputfile.write("<stringConstant> #{token} </stringConstant>\n")
	end

	def writeVar()
		self.writeIndentifier() #first varName
		@tokenizer.advance()
		isSemicolon = @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ";"
		while !isSemicolon
			self.writeSymbol() #,
			@tokenizer.advance()
			self.writeIndentifier() #varName
			@tokenizer.advance()
			isSemicolon = @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ";"
		end
		self.writeSymbol()
	end

	def throwError(messge)
		raise Exception.new(messge)
	end
end