require 'strscan'

class JackTokenizer

def initialize(file, fileName)
	@tokenOutputFile = File.new(fileName.split(".")[0] + "T.xml", "w")
	self.analysizeFile(file)
end

def analysizeFile(file)
	#删除所有注释
	file = file.gsub(/((?:\/\*(?:[^*]|(?:\*+[^*\/]))*\*+\/)|(?:\/\/.*))/, '').split.join(' ')
	puts "remove comments:"
	puts file

	#代码转成token
	self.scanTextToToken(file)
end

def scanTextToToken(text)
	@tokens = []
	scanner = StringScanner.new(text)
	#puts !scanner.eos?
	while !scanner.eos?
		# 扫描字符串类型
		stringToken = scanner.scan(/"[^"]*"/)
		if stringToken
			#puts "追加stringToken:#{stringToken}"
			@tokens << stringToken
			scanner.scan(/\s+/)
			next
		end
		# 扫描symbol
		symbolToken = scanner.scan(/\{|\}|\(|\)|\[|\]|\.|\,|\;|\+|\-|\*|\/|\&|\||\<|\>|\=|\~/)
		if symbolToken
			#puts "追加symbolToken:#{symbolToken}"
			@tokens << symbolToken
			scanner.scan(/\s+/)
			next
		end
		# 扫描其他tokenotherToken
		otherToken = scanner.scan_until(/\s+|\{|\}|\(|\)|\[|\]|\.|\,|\;|\+|\-|\*|\/|\&|\||\<|\>|\=|\~/)
		if otherToken
			otherToken = otherToken[0..otherToken.length-2]
			#puts "追加otherToken:#{otherToken}"
			scanner.pos = scanner.pos-1
			@tokens << otherToken
			scanner.scan(/\s+/)
			next
		end
	end
	puts "解析成token"
	puts @tokens
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


