require_relative 'JackTokenizer'
require_relative 'SymbolTable'
require_relative 'VMWriter'

$OPETATOR = ["+", "-", "*", "/", "&", "|", "&lt;", "&gt;", "&amp;", "="]
$OPTOCMD = {"+"=>"add", "-"=>"sub", "*"=>"call Math.multiply 2", "/"=>"call Math.divide 2", "&lt;"=>"lt", "&gt;"=>"gt", "="=>"eq", "&amp;"=>"and", "|"=>"or"}
$UNARYCMD = {"-"=>"neg", "~"=>"not"}

class CompilationEngine

	def initialize(tokenizer, outputfile, vmfile)
		@outputfile = outputfile
		@vmfile = vmfile

		@tokenizer = tokenizer
		@symbolTable = SymbolTable.new()
		@vmWriter = VMWriter.new(@vmfile)
		@className = ""
		@currentMethodName = ""
		@curFunctionType = ""
		@ifBackTrace = []
		@ifTotle = -1
		@ifCount = -1
		@whileBackTrace = []
		@whileTotle = -1
		@whileCount = -1

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
		@symbolTable.printSymbols()
		self.compileSubroutine() #subroutine*
		#self.writeSymbol() #}
		#@outputfile.write("</class>\n")
		@vmWriter.close()
	end

	#编译静态变量或成员变量的声明
	def compileClassVarDec
		varCount = 0
		isVar = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "static" || @tokenizer.keyword() == "field")
		while isVar
			#@outputfile.write("<classVarDec>\n")
			#self.writeKeyword() #(static|field)
			kind = getKeyword()
			@tokenizer.advance()
			#self.writeType()
			type = getType()
			@tokenizer.advance()
			varCount = varCount + self.writeVarToSymbolTable(kind, type)
			@tokenizer.advance()
			isVar = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "static" || @tokenizer.keyword() == "field")
			#@outputfile.write("</classVarDec>\n")
		end
		return
	end

	#编译局部变量
	def compileVarDec
		varCount = 0
		isVar = @tokenizer.tokenType == "KEYWORD" && @tokenizer.keyword() == "var"
		while isVar
			#@outputfile.write("<varDec>\n")
			#self.writeKeyword() #var
			kind = getKeyword()
			@tokenizer.advance()
			#self.writeType()
			type = getType()
			@tokenizer.advance()
			varCount = varCount + self.writeVarToSymbolTable(kind, type)
			@tokenizer.advance()
			isVar = @tokenizer.tokenType == "KEYWORD" && @tokenizer.keyword() == "var"
			#@outputfile.write("</varDec>\n")
		end
		return varCount
	end

	def compileSubroutine
		isSubroutine = @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "constructor" || @tokenizer.keyword() == "function" || @tokenizer.keyword() == "method")
		while isSubroutine
			#@outputfile.write("<subroutineDec>\n")
			#self.writeKeyword() #(method type)
			@curFunctionType = self.getKeyword()
			@tokenizer.advance()
			if @tokenizer.tokenType == "KEYWORD" && (@tokenizer.keyword() == "int" || @tokenizer.keyword() == "char" || @tokenizer.keyword() == "boolean" || @tokenizer.keyword() == "void")
				#self.writeKeyword() #(basic type)
			elsif @tokenizer.tokenType == "IDENTIFIER"
				#self.writeIndentifier() #(class type)
			end
			puts "开始编译：#{@currentMethodName}------------------------------------"
			self.resetValues()
			@symbolTable.startSubroutine() #清空函数symbolTable
			@tokenizer.advance()
			#self.writeIndentifier() #method name
			@currentMethodName = "#{@className}.#{self.getIndentifier()}"
			@tokenizer.advance()
			#self.writeSymbol() #(
			@tokenizer.advance()
			paramCount = self.compileParameterList() #parameterList
			#self.writeSymbol() #)
			@tokenizer.advance()
			self.compileSubroutineBody() #subroutineBody
			#@outputfile.write("</subroutineDec>\n")
			@tokenizer.advance()
			puts "编译完成：#{@currentMethodName}------------------------------------"
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
		return paramCount
		#@outputfile.write("</parameterList>\n")
	end

	#编译函数体
	def compileSubroutineBody()
		#@outputfile.write("<subroutineBody>\n")
		#self.writeSymbol() #{
		@tokenizer.advance()
		varCount = self.compileVarDec()
		@symbolTable.printSymbols()
		@vmWriter.writeFunction(@currentMethodName, varCount) #新的函数名+该函数局部变量的个数
		if @curFunctionType == "constructor"
			self.compileConstructor()
		elsif @curFunctionType == "method"
			self.compileMethod()
		end
		self.compileStatements()
		#self.writeSymbol() #}
		#@outputfile.write("</subroutineBody>\n")
	end

	# 编译构造函数，开辟实例内存
	def compileConstructor
		filedCount = @symbolTable.varCount("field")
		@vmWriter.writePushNumber(filedCount)
		@vmWriter.writeCall("Memory.alloc", 1)
		@vmWriter.writePop("pointer", 0) #把实例内存地址pop到THIS
	end

	# 实例方法，先把修改this指针
	def compileMethod
		@vmWriter.writePush("argument", 0)
		@vmWriter.writePop("pointer", 0)
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
		#@outputfile.write("<letStatement>\n")
		#self.writeKeyword() #let
		@tokenizer.advance()
		#self.writeIndentifier()
		varName = self.getIndentifier()
		@tokenizer.advance()
		isArray = false
		if @tokenizer.symbol() == "[" #数组
			isArray = true
			#self.writeSymbol() #[
			@tokenizer.advance()
			self.compileExpression()
			self.pushVarName(varName)
			@vmWriter.writeArithmetic("add")
			#self.writeSymbol() #]	
			@tokenizer.advance()		
		end
		#self.writeSymbol() #=
		@tokenizer.advance()
		self.compileExpression()
		if isArray
			@vmWriter.writePop("temp", 0) #temp0 = expression above
			@vmWriter.writePop("pointer", 1) #数组指向that
			@vmWriter.writePush("temp", 0)
			@vmWriter.writePop("that", 0)
		else
			#self.writeSymbol() #;	
			#@outputfile.write("</letStatement>\n")
			symbolKind = @symbolTable.kindOf(varName)
			symbolIndex = @symbolTable.indexOf(varName)
			if symbolKind == "argument" || symbolKind == "local" || symbolKind == "static"
				@vmWriter.writePop(symbolKind, symbolIndex) # 把expression的值pop到var
			elsif symbolKind == "field"
				@vmWriter.writePop("this", symbolIndex) # 把expression的值pop到this段
			else
				raise "不能识别"
			end
		end
	end

	def compileIF
		@ifBackTrace << @ifCount
		@ifTotle = @ifTotle + 1
		@ifCount = @ifTotle
		#@outputfile.write("<ifStatement>\n")
		#self.writeKeyword() #if
		@tokenizer.advance()
		#self.writeSymbol() #(
		@tokenizer.advance()
		self.compileExpression()
		@vmWriter.writeIf("IF_TRUE#{@ifCount}")
		@vmWriter.writeGoto("IF_FALSE#{@ifCount}")
		@vmWriter.writeLabel("IF_TRUE#{@ifCount}")
		#self.writeSymbol() #)
		@tokenizer.advance()
		#self.writeSymbol() #{
		@tokenizer.advance()
		self.compileStatements()
		#self.writeSymbol() #}
		@tokenizer.advance()
		if @tokenizer.keyword() == "else" #compile else
			#self.writeKeyword() #else
			@vmWriter.writeGoto("IF_END#{@ifCount}")
			@vmWriter.writeLabel("IF_FALSE#{@ifCount}")
			@tokenizer.advance()
			#self.writeSymbol() #{
			@tokenizer.advance()
			self.compileStatements()
			@vmWriter.writeLabel("IF_END#{@ifCount}")
			#self.writeSymbol() #}
		else
			@tokenizer.backward() #返回到}处
			@vmWriter.writeLabel("IF_FALSE#{@ifCount}")
		end
		@ifCount = @ifBackTrace.pop()
		#@outputfile.write("</ifStatement>\n")
	end

	def compileWhile
		@whileBackTrace << @whileCount
		@whileTotle = @whileTotle + 1
		@whileCount = @whileTotle
		@vmWriter.writeLabel("WHILE_EXP#{@whileCount}")
		#@outputfile.write("<whileStatement>\n")
		#self.writeKeyword() #while
		@tokenizer.advance()
		#self.writeSymbol() #(
		@tokenizer.advance()
		self.compileExpression()
		@vmWriter.writeArithmetic("not")
		@vmWriter.writeIf("WHILE_END#{@whileCount}")
		#self.writeSymbol() #)
		@tokenizer.advance()
		#self.writeSymbol() #{
		@tokenizer.advance()
		self.compileStatements()
		@vmWriter.writeGoto("WHILE_EXP#{@whileCount}")
		@vmWriter.writeLabel("WHILE_END#{@whileCount}")
		#self.writeSymbol() #}
		#@outputfile.write("</whileStatement>\n")
		@whileCount = @whileBackTrace.pop
	end

	def compileReturn
		#@outputfile.write("<returnStatement>\n")
		#self.writeKeyword() #return
		@tokenizer.advance()
		if @tokenizer.symbol() == ";" #数组
			#self.writeSymbol() #;
			@vmWriter.writePushNumber(0) #默认push0
			@vmWriter.writeReturn() #return
		else
			self.compileExpression()
			#self.writeSymbol() #;
			@vmWriter.writeReturn() #return
		end
		#@outputfile.write("</returnStatement>\n")
	end

	def compileDo
		#@outputfile.write("<doStatement>\n")
		#self.writeKeyword() #do
		@tokenizer.advance()
		self.compileSubroutineCall()
		@vmWriter.writePop("temp", 0) #do语句总是调用返回类型为void的函数，所以最后弹出(并忽略)调用函数的返回值
		#@outputfile.write("</doStatement>\n")
	end

	def compileSubroutineCall
		#self.writeIndentifier() #方法名或类对象或实例对象
		isVoid = false
		firstSymbol = self.getIndentifier()
		@tokenizer.advance()
		if @tokenizer.symbol() == "(" #调内部方法分支
			#self.writeSymbol() #(
			@tokenizer.advance()
			@vmWriter.writePush("pointer", 0) #调用实例方法，先push this
			paramCount = self.compileExpressionList()
			methodName = "#{@className}.#{firstSymbol}"
			@vmWriter.writeCall(methodName, paramCount + 1)
			#self.writeSymbol() #)
			@tokenizer.advance()
			#self.writeSymbol() #;
		elsif @tokenizer.symbol() == "." #调外部方法分支
			#self.writeSymbol() #.
			@tokenizer.advance()
			#self.writeIndentifier() #方法名
			className = firstSymbol
			methodName = self.getIndentifier() 
			@tokenizer.advance()
			#self.writeSymbol() #(
			@tokenizer.advance()
			symbolKind = @symbolTable.kindOf(firstSymbol)
			symbolIndex = @symbolTable.indexOf(firstSymbol)
			isInstanceMethod = symbolKind != "NONE" && symbolIndex != "NONE"
			if  isInstanceMethod #调用实例的方法
				if symbolKind == "field"
					@vmWriter.writePush("this", symbolIndex) #push this
				else
					if @curFunctionType == "method" && symbolKind == "argument"
						symbolIndex = symbolIndex + 1
					end
					@vmWriter.writePush(symbolKind, symbolIndex)
				end
				className = @symbolTable.typeOf(firstSymbol)
			end
			paramCount = self.compileExpressionList()
			if isInstanceMethod
				paramCount = paramCount + 1
			end
			callName = "#{className}.#{methodName}"
			@vmWriter.writeCall(callName, paramCount)
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
			#self.writeSymbol()
			#puts "get symbol: #{self.getSymbol()}"
			opretator = $OPTOCMD[self.getSymbol()] #操作符
			@tokenizer.advance()
			self.compileTerm()
			@vmWriter.writeArithmetic(opretator)
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
		return paramCount
		#@outputfile.write("</expressionList>\n")
	end

	def compileTerm
		#@outputfile.write("<term>\n")
		if @tokenizer.symbol() == "-" || @tokenizer.symbol() == "~" #unary term
			#self.writeSymbol() #~
			opetator = $UNARYCMD[self.getSymbol()] 
			@tokenizer.advance()
			self.compileTerm()
			@vmWriter.writeArithmetic(opetator)
		elsif @tokenizer.tokenType == "KEYWORD"
			#self.writeKeyword()
			keyword = self.getKeyword()
			if keyword == "false" || keyword == "null"
				@vmWriter.writePushNumber("0")
			elsif keyword == "true"
				@vmWriter.writePushNumber("0")
				@vmWriter.writeArithmetic("not") #-1代表true
			elsif keyword == "this"
				@vmWriter.writePush("pointer", 0)
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
			#self.writeString()
			string = self.getString()
			puts "发现string：#{string}"
			self.processString(string)
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
				varName = self.getIndentifier()
				self.pushVarName(varName)
				@tokenizer.advance()
			elsif secondToken == "[" #varName[expression]
				#self.writeIndentifier()
				varName = self.getIndentifier()
				@tokenizer.advance()
				#self.writeSymbol() #[
				@tokenizer.advance()
				self.compileExpression()
				self.pushVarName(varName)
				@vmWriter.writeArithmetic("add")
				@vmWriter.writePop("pointer", 1) #修改That
				@vmWriter.writePush("that", 0)
				#self.writeSymbol() #]
				@tokenizer.advance()
			elsif secondToken == "(" || secondToken == "." #subroutineCall
				#self.writeIndentifier() #方法名或类对象或实例对象
				firstSymbol = self.getIndentifier()
				@tokenizer.advance()
				if @tokenizer.symbol() == "(" #调内部方法分支
					#self.writeSymbol() #(
					@tokenizer.advance()
					paramCount = self.compileExpressionList()
					methodName = "#{@className}.#{firstSymbol}"
					@vmWriter.writePush("pointer", 0) #调用实例方法，先push自己
					@vmWriter.writeCall(methodName, paramCount + 1)
					#self.writeSymbol() #)
					@tokenizer.advance()
				elsif @tokenizer.symbol() == "." #调外部方法分支
					#self.writeSymbol() #.
					@tokenizer.advance()
					#self.writeIndentifier() #方法名
					className = firstSymbol
					methodName = self.getIndentifier() 
					@tokenizer.advance()
					#self.writeSymbol() #(
					@tokenizer.advance()
					symbolKind = @symbolTable.kindOf(firstSymbol)
					symbolIndex = @symbolTable.indexOf(firstSymbol)
					isInstanceMethod = symbolKind != "NONE" && symbolIndex != "NONE"
					if  isInstanceMethod #调用实例的方法
						if symbolKind == "field"
							@vmWriter.writePush("this", symbolIndex) #push this
						else
							if @curFunctionType == "method" && symbolKind == "argument"
								symbolIndex = symbolIndex + 1
							end
							@vmWriter.writePush(symbolKind, symbolIndex)
						end
						className = @symbolTable.typeOf(firstSymbol)
					end
					paramCount = self.compileExpressionList()
					if isInstanceMethod
						paramCount = paramCount + 1
					end
					callName = "#{className}.#{methodName}"
					@vmWriter.writeCall(callName, paramCount)
					#self.writeSymbol() #)
					@tokenizer.advance()
				end
			end
		end
		#@outputfile.write("</term>\n")
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
		varCount = 0
		#self.writeIndentifier() #first varName
		firstVarName = self.getIndentifier()
		# puts "写入符号表：#{firstVarName},#{type},#{kind}"
		@symbolTable.define(firstVarName, type, kind)
		varCount = varCount + 1
		@tokenizer.advance()
		isSemicolon = @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ";"
		while !isSemicolon
			#self.writeSymbol() #,
			@tokenizer.advance()
			#self.writeIndentifier() #varName
			nextVarName = self.getIndentifier()
			#puts "写入符号表：#{nextVarName},#{type},#{kind}"
			@symbolTable.define(nextVarName, type, kind)
			varCount = varCount + 1
			@tokenizer.advance()
			isSemicolon = @tokenizer.tokenType == "SYMBOL" && @tokenizer.symbol() == ";"
		end
		#self.writeSymbol()
		return varCount
	end

	def pushVarName(varName)
		symbolKind = @symbolTable.kindOf(varName)
		symbolIndex = @symbolTable.indexOf(varName)
		if symbolKind == "field"
			@vmWriter.writePush("this", symbolIndex) # 实例变量
		else
			if @curFunctionType == "method" && symbolKind == "argument"
				symbolIndex = symbolIndex + 1
			end
			@vmWriter.writePush(symbolKind, symbolIndex) # 其他变量	
		end
	end

	def processString(string)
		charArray = string.each_byte.to_a
		@vmWriter.writePushNumber(charArray.length)
		@vmWriter.writeCall("String.new", 1) #创建字符串对象
		charArray.each do |c|
			@vmWriter.writePushNumber(c)
			@vmWriter.writeCall("String.appendChar", 2) #追加字符到字符串
		end
	end

	def resetValues
		@ifBackTrace = []
		@ifTotle = -1
		@ifCount = -1
		@whileBackTrace = []
		@whileTotle = -1
		@whileCount = -1
	end

	def throwError(messge)
		raise Exception.new(messge)
	end
end