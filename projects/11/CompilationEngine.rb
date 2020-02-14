require_relative 'JackTokenizer'
require_relative 'SymbolTable'
require_relative 'VMWriter'

$OPETATOR = ["+", "-", "*", "/", "&", "|", "&lt;", "&gt;", "&amp;", "="]
$OPTOCMD = {"+"=>"add", "-"=>"sub", "*"=>"call Math.multiply 2", "/"=>"call Math.divide 2", "<"=>"lt", ">"=>"gt", "="=>"eq", "&"=>"and", "|"=>"or"}
$UNARYCMD = {"-"=>"neg", "~"=>"not"}


class CompilationEngine

	def initialize(tokenizer, outputfile, vmfile)
		@outputfile = outputfile
		@vmfile = vmfile

		@tokenizer = tokenizer
		@symbolTable = SymbolTable.new()
		@vmWriter = VMWriter.new()
		@className = ""

		self.compileClass()
	end

	#compile method
	#编译整个类
	def compileClass
		#@outputfile.write("<class>\n")
		@tokenizer.advance()
		#self.writeKeyword() #class
		@tokenizer.advance()
		#self.writeIndentifier() #className
		@className = self.getIndentifier()
		@tokenizer.advance()
		#self.writeSymbol() #{
		@tokenizer.advance()
		self.compileClassVarDec() #classVarDec*
		self.compileSubroutine() #subroutine*
		#self.writeSymbol() #}
		#@outputfile.write("</class>\n")
	end

	#编译静态变量或成员变量的声明
	def compileClassVarDec
		isVar = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "static" || @tokenizer.keyword() == "field")
		while isVar
			#@outputfile.write("<classVarDec>\n")
			#self.writeKeyword() #(static|field)
			kind = getKeyword()
			@tokenizer.advance()
			#self.writeType()
			type = getType()
			@tokenizer.advance()
			self.writeVarToSymbolTable(kind, type)
			@tokenizer.advance()
			isVar = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "static" || @tokenizer.keyword() == "field")
			#@outputfile.write("</classVarDec>\n")
		end
		return
	end

	#编译局部变量
	def compileVarDec
		isVar = @tokenizer.tokenType == "KEYWORD" && @tokenizer.keyword() == "var"
		while isVar
			#@outputfile.write("<varDec>\n")
			#self.writeKeyword() #var
			kind = getKeyword()
			@tokenizer.advance()
			#self.writeType()
			type = getType()
			@tokenizer.advance()
			self.writeVarToSymbolTable(kind, type)
			@tokenizer.advance()
			isVar = @tokenizer.tokenType == "KEYWORD" && @tokenizer.keyword() == "var"
			#@outputfile.write("</varDec>\n")
		end
		return
	end

	def compileSubroutine
		isSubroutine = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "constructor" || @tokenizer.keyword() == "function" || @tokenizer.keyword() == "method")
		while isSubroutine
			#@outputfile.write("<subroutineDec>\n")
			#self.writeKeyword() #(method type)
			@tokenizer.advance()
			if @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "int" || @tokenizer.keyword() == "char" || @tokenizer.keyword() == "boolean" || @tokenizer.keyword() == "void")
				#self.writeKeyword() #(basic type)
			elsif @tokenizer.tokenType == "IDENTIFIER"
				#self.writeIndentifier() #(class type)
			end
			@tokenizer.advance()
			#self.writeIndentifier() #method name
			methodName = "#{@className}.#{self.getIndentifier()}"
			@tokenizer.advance()
			#self.writeSymbol() #(
			@tokenizer.advance()
			paramCount = self.compileParameterList() #parameterList
			#self.writeSymbol() #)
			@tokenizer.advance()
			@symbolTable.startSubroutine() #清空函数symbolTable
			vmWriter.writeFunction(methodName, paramCount) #开始写新函数
			self.compileSubroutineBody() #subroutineBody
			#@outputfile.write("</subroutineDec>\n")

			@tokenizer.advance()
			isSubroutine = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "constructor" || @tokenizer.keyword() == "function" || @tokenizer.keyword() == "method")
		end

		return
	end

	#编译参数列表
	def compileParameterList()
		#@outputfile.write("<parameterList>\n")
		paramCount = 0
		paramEnd = @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ")"
		while !paramEnd
			#self.writeType() #type
			type = self.getType()
			@tokenizer.advance()
			#self.writeIndentifier() #name
			varName = self.getIndentifier()
			@tokenizer.advance()
			@symbolTable.define(varName, type, "arg")
			paramCount = paramCount + 1
			if @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ","
				#self.writeSymbol()
				@tokenizer.advance()
			end
			paramEnd = @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ")"
		end
		#@outputfile.write("</parameterList>\n")
	end

	#编译函数体
	def compileSubroutineBody()
		#@outputfile.write("<subroutineBody>\n")
		#self.writeSymbol() #{
		@tokenizer.advance()
		self.compileVarDec()
		self.compileStatements()
		#self.writeSymbol() #}
		#@outputfile.write("</subroutineBody>\n")
	end

	def compileStatements
		#@outputfile.write("<statements>\n")
		statementsEnd = @tokenizer.symbol() == "}"
		while !statementsEnd
			if @tokenizer.keyword() == "do"
				self.compileDo()
			elsif @tokenizer.keyword() == "let"
				self.compileLet()
			elsif @tokenizer.keyword() == "while"
				self.compileWhile()
			elsif @tokenizer.keyword() == "if"
				self.compileIF()
			elsif @tokenizer.keyword() == "return"
				self.compileReturn()
			end
			@tokenizer.advance()
			statementsEnd = @tokenizer.symbol() == "}"
		end
		#@outputfile.write("</statements>\n")
	end

	def compileLet
		@outputfile.write("<letStatement>\n")
		self.writeKeyword() #let
		@tokenizer.advance()
		self.writeIndentifier()
		@tokenizer.advance()
		if @tokenizer.symbol() == "[" #数组
			self.writeSymbol() #[
			@tokenizer.advance()
			self.compileExpression()
			self.writeSymbol() #]	
			@tokenizer.advance()				
		end
		self.writeSymbol() #=
		@tokenizer.advance()
		self.compileExpression()
		self.writeSymbol() #;	
		@outputfile.write("</letStatement>\n")
	end

	def compileIF
		@outputfile.write("<ifStatement>\n")
		self.writeKeyword() #if
		@tokenizer.advance()
		self.writeSymbol() #(
		@tokenizer.advance()
		self.compileExpression()
		self.writeSymbol() #)
		@tokenizer.advance()
		self.writeSymbol() #{
		@tokenizer.advance()
		self.compileStatements()
		self.writeSymbol() #}

		@tokenizer.advance()
		if @tokenizer.keyword() == "else" #compile else
			self.writeKeyword() #else
			@tokenizer.advance()
			self.writeSymbol() #{
			@tokenizer.advance()
			self.compileStatements()
			self.writeSymbol() #}
		else
			@tokenizer.backward() #返回到}处
		end
		@outputfile.write("</ifStatement>\n")
	end

	def compileWhile
		@outputfile.write("<whileStatement>\n")
		self.writeKeyword() #while
		@tokenizer.advance()
		self.writeSymbol() #(
		@tokenizer.advance()
		self.compileExpression()
		self.writeSymbol() #)
		@tokenizer.advance()
		self.writeSymbol() #{
		@tokenizer.advance()
		self.compileStatements()
		self.writeSymbol() #}
		@outputfile.write("</whileStatement>\n")
	end

	def compileReturn
		#@outputfile.write("<returnStatement>\n")
		#self.writeKeyword() #return
		returnWord = self.getKeyword()
		@tokenizer.advance()
		if @tokenizer.symbol() == ";" #数组
			#self.writeSymbol() #;
			@vmWriter.writePushNumber(0) #默认push0
			@vmWriter.writeReturn(returnWord) #return
		else
			self.compileExpression()
			#self.writeSymbol() #;
			@vmWriter.writeReturn(returnWord) #return
		end
		#@outputfile.write("</returnStatement>\n")
	end

	def compileDo
		#@outputfile.write("<doStatement>\n")
		#self.writeKeyword() #do
		@tokenizer.advance()
		self.compileSubroutineCall()
		#@outputfile.write("</doStatement>\n")
	end

	def compileSubroutineCall
		#self.writeIndentifier() #方法名或类对象或实例对象
		firstSymbol = self.getIndentifier()
		@tokenizer.advance()
		if @tokenizer.symbol() == "(" #调内部方法分支
			#self.writeSymbol() #(
			@tokenizer.advance()
			paramCount = self.compileExpressionList()
			methodName = "#{@className}.#{firstSymbol}"
			@vmWriter.writeCall(methodName, paramCount)
			#self.writeSymbol() #)
			@tokenizer.advance()
			#self.writeSymbol() #;
		elsif @tokenizer.symbol() == "." #调外部方法分支
			#self.writeSymbol() #.
			@tokenizer.advance()
			#self.writeIndentifier() #方法名
			methodName = "#{firstSymbol}.#{self.getIndentifier()}"
			@tokenizer.advance()
			#self.writeSymbol() #(
			@tokenizer.advance()
			paramCount = self.compileExpressionList()
			@vmWriter.writeCall(methodName, paramCount)
			#self.writeSymbol() #)
			@tokenizer.advance()
			#self.writeSymbol() #;
		end
	end

	def compileExpression
		#@outputfile.write("<expression>\n")
		self.compileTerm()
		termEnd = !($OPETATOR.include? @tokenizer.symbol())
		if !termEnd
			opretator = $OPTOCMD[self.writeSymbol()] #操作符
			@tokenizer.advance()
			self.compileTerm()
			vmWriter.writeArithmetic(opretator)
			termEnd = !($OPETATOR.include? @tokenizer.symbol())
		end
		#@outputfile.write("</expression>\n")
	end

	def compileExpressionList
		#@outputfile.write("<expressionList>\n")
		paramCount = 0
		if @tokenizer.symbol() != ")"
			self.compileExpression()
			paramCount = paramCount + 1
			expressionEnd = @tokenizer.symbol() != ","
			while !expressionEnd
				#self.writeSymbol() #,
				@tokenizer.advance()	
				self.compileExpression()
				paramCount = paramCount + 1
				expressionEnd = @tokenizer.symbol() != ","
			end			
		end
		#@outputfile.write("</expressionList>\n")
	end

	def compileTerm
		@outputfile.write("<term>\n")
		if @tokenizer.symbol() == "-" || @tokenizer.symbol() == "~" #unary term
			#self.writeSymbol() #~
			opetator = $OPTOCMD[selg.getSymbol()] 
			@tokenizer.advance()
			self.compileTerm()
			@vmWriter.writeArithmetic(opetator)
		elsif @tokenizer.tokenType == "KEYWORD"
			#self.writeKeyword()
			keyword = self.getKeyword()
			if keyword == "false" || keyword == "null"
				@vmWriter.writePushNumber("0")
			elsif keyword == "true"
				@vmWriter.writePushNumber("1")
				@vmWriter.writeArithmetic("neg") #-1代表true
			else
				raise "#{keyword}是不可识别符号（只识别ture, false, null）"
			end
			@tokenizer.advance()
		elsif @tokenizer.tokenType == "INT-CONST"
			#self.writeNumber()
			number = self.getNumber()
			@vmWriter.writePushNumber(number)
			@tokenizer.advance()
		elsif @tokenizer.tokenType == "STRING-CONST"
			raise "这里处理字符串"
			self.writeString()
			@tokenizer.advance()
		elsif @tokenizer.symbol() == "(" #(expression)
			#self.writeSymbol() #(
			@tokenizer.advance()
			self.compileExpression()
			#self.writeSymbol() #)
			@tokenizer.advance()
		else #varName | varName[expression] | subroutineCall
			firstToken = @tokenizer.identifier()
			@tokenizer.advance()
			secondToken = @tokenizer.symbol()
			@tokenizer.backward()
			if secondToken != "[" && secondToken != "(" && secondToken != "." #varName
				#self.writeIndentifier()
				varName = self.getString()
				symbolKind = @symbolTable.kindOf(varName)
				symbolIndex = @symbolTable.indexOf(varName)
				@vmWriter.writePush(symbolKind, symbolIndex) # 处理变量
				@tokenizer.advance()
			elsif secondToken == "[" #varName[expression]
				self.writeIndentifier()
				@tokenizer.advance()
				self.writeSymbol() #[
				@tokenizer.advance()
				self.compileExpression()	
				self.writeSymbol() #]
				@tokenizer.advance()
			elsif secondToken == "(" || secondToken == "." #subroutineCall
				self.writeIndentifier() #方法名或类对象或实例对象
				@tokenizer.advance()
				if @tokenizer.symbol() == "(" #调内部方法分支
					self.writeSymbol() #(
					@tokenizer.advance()
					self.compileExpressionList()
					self.writeSymbol() #)
					@tokenizer.advance()
				elsif @tokenizer.symbol() == "." #调外部方法分支
					self.writeSymbol() #.
					@tokenizer.advance()
					self.writeIndentifier() #方法名
					@tokenizer.advance()
					self.writeSymbol() #()
					@tokenizer.advance()
					self.compileExpressionList()
					self.writeSymbol() #)
					@tokenizer.advance()
				end
			end
		end
		@outputfile.write("</term>\n")
	end
	
	#helpers
	def writeKeyword()
		token = @tokenizer.keyword()
		if @tokenizer.tokenType() != "KEYWORD"
			self.throwError("#{token} 不是KEYWORD")
		end
		@outputfile.write("<keyword> #{token} </keyword>\n")
	end

	def getKeyword
		token = @tokenizer.keyword()
		if @tokenizer.tokenType() != "KEYWORD"
			self.throwError("#{token} 不是KEYWORD")
		end
		return token
	end

	def writeIndentifier()
		token = @tokenizer.identifier()
		if @tokenizer.tokenType() != "IDENTIFIER"
			self.throwError("#{token} 不是IDENTIFIER")
		end
		@outputfile.write("<identifier> #{token} </identifier>\n")
	end

	def getIndentifier()
		token = @tokenizer.identifier()
		if @tokenizer.tokenType() != "IDENTIFIER"
			self.throwError("#{token} 不是IDENTIFIER")
		end
		return token
		@outputfile.write("<identifier> #{token} </identifier>\n")
	end

	def writeSymbol()
		token = @tokenizer.symbol()
		if @tokenizer.tokenType() != "SYMBOL"
			self.throwError("#{token} 不是SYMBOL")
		end
		@outputfile.write("<symbol> #{token} </symbol>\n")
	end

	def getSymbol()
		token = @tokenizer.symbol()
		if @tokenizer.tokenType() != "SYMBOL"
			self.throwError("#{token} 不是SYMBOL")
		end
		return token
	end

	def writeNumber()
		token = @tokenizer.iniVal()
		if @tokenizer.tokenType() != "INT-CONST"
			self.throwError("#{token} 不是INT-CONST")
		end
		@outputfile.write("<integerConstant> #{token} </integerConstant>\n")
	end

	def getNumber()
		token = @tokenizer.iniVal()
		if @tokenizer.tokenType() != "INT-CONST"
			self.throwError("#{token} 不是INT-CONST")
		end
		return token
	end

	def writeString()
		token = @tokenizer.stringValue()
		if @tokenizer.tokenType() != "STRING-CONST"
			self.throwError("#{token} 不是STRING-CONST")
		end
		@outputfile.write("<stringConstant> #{token} </stringConstant>\n")
	end

	def getString()
		token = @tokenizer.stringValue()
		if @tokenizer.tokenType() != "STRING-CONST"
			self.throwError("#{token} 不是STRING-CONST")
		end
		return token
	end

	def writeType
		if @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "int" || @tokenizer.keyword() == "char" || @tokenizer.keyword() == "boolean")
			self.writeKeyword() #(basic type)
		elsif @tokenizer.tokenType == "IDENTIFIER"
			self.writeIndentifier() #(class type)
		end
	end

	def getType
		if @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "int" || @tokenizer.keyword() == "char" || @tokenizer.keyword() == "boolean")
			return self.getKeyword()
		elsif @tokenizer.tokenType == "IDENTIFIER"
			return self.getIndentifier()
		end
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

	def writeVarToSymbolTable(kind, type)
		#self.writeIndentifier() #first varName
		firstVarName = self.getIndentifier()
		@symbolTable.define(firstVarName, type, kind)
		@tokenizer.advance()
		isSemicolon = @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ";"
		while !isSemicolon
			#self.writeSymbol() #,
			@tokenizer.advance()
			#self.writeIndentifier() #varName
			nextVarName = self.getIndentifier()
			@symbolTable.define(nextVarName, type, kind)
			@tokenizer.advance()
			isSemicolon = @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ";"
		end
		#self.writeSymbol()
	end

	def throwError(messge)
		raise Exception.new(messge)
	end
end