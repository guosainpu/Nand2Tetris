require 'strscan'

$KEYWORDS = ["class", "method", "function", "constructor", "int", "boolean", "char", "void", "var", "static", "field", "let", "do", "if", "else", "while", "return", "true", "false", "null", "this"]
$SYMBOL = ["{", "}", "(", ")", "[", "]", ".", ",", ";", "+", "-", "*", "/", "&", "|", "<", ">", "=", "~"]

class JackTokenizer

def initialize(file, fileName)
	@tokenOutputFile = File.new(fileName.split(".")[0] + "TT.xml", "w")
	self.analysizeFile(file)
end

def analysizeFile(file)
	#删除所有注释
	file = file.gsub(/((?:\/\*(?:[^*]|(?:\*+[^*\/]))*\*+\/)|(?:\/\/.*))/, '').split.join(' ')
	puts "remove comments:"
	puts file

	#代码转成token
	@tokens = self.scanTextToToken(file)
	self.writeTokensTofile(@tokens)
end

def scanTextToToken(text)
	tokens = []
	scanner = StringScanner.new(text)
	#puts !scanner.eos?
	while !scanner.eos?
		# 扫描字符串类型
		stringToken = scanner.scan(/"[^"]*"/)
		if stringToken
			#puts "追加stringToken:#{stringToken}"
			tokens << stringToken
			scanner.scan(/\s+/)
			next
		end
		# 扫描symbol
		symbolToken = scanner.scan(/\{|\}|\(|\)|\[|\]|\.|\,|\;|\+|\-|\*|\/|\&|\||\<|\>|\=|\~/)
		if symbolToken
			#puts "追加symbolToken:#{symbolToken}"
			tokens << symbolToken
			scanner.scan(/\s+/)
			next
		end
		# 扫描其他tokenotherToken
		otherToken = scanner.scan_until(/\s+|\{|\}|\(|\)|\[|\]|\.|\,|\;|\+|\-|\*|\/|\&|\||\<|\>|\=|\~/)
		if otherToken
			otherToken = otherToken[0..otherToken.length-2]
			#puts "追加otherToken:#{otherToken}"
			scanner.pos = scanner.pos-1
			tokens << otherToken
			scanner.scan(/\s+/)
			next
		end
	end
	#puts "解析成token"
	#puts tokens
	return tokens
end

def writeTokensTofile(tokens)
	@tokenOutputFile.write("<tokens>\n")
	tokens.each do |token|
		if self.isKeyword(token)
			@tokenOutputFile.write("<keyword> #{token} </keyword>\n")
		elsif self.isSymbol(token)
			token = self.convertSymbol(token)
			@tokenOutputFile.write("<symbol> #{token} </symbol>\n")
		elsif self.isNumber(token)
			@tokenOutputFile.write("<integerConstant> #{token} </integerConstant>\n")
		elsif self.isString(token)
			@tokenOutputFile.write("<stringConstant> #{token[1..token.length-2]} </stringConstant>\n")
		else
			@tokenOutputFile.write("<identifier> #{token} </identifier>\n")
		end
	end
	@tokenOutputFile.write("</tokens>\n")
	@tokenOutputFile.close()
end

def isKeyword(token)
	return $KEYWORDS.include? token
end

def isSymbol(token)
	return $SYMBOL.include? token
end

def isNumber(token)
	return token.match(/\d+/)
end

def isString(token)
	return token.match(/"[^"]*"/)
end

def convertSymbol(symbol)
	if symbol == "<" || symbol == ">" || symbol == "&"
		return {"<"=>"&lt;", ">"=>"&gt;", "&"=>"&amp;"}[symbol]
	end
	return symbol
end

# public method
def hasMoreToken
	
end

def tokenType
	
end

# 获取具体token的值
def keyword
	
end

def symbol
	
end

def identifier
	
end

def iniVal
	
end

def stringValue
	
end

def method_name
	
end

end


