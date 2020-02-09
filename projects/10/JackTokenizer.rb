class JackTokenizer

def initialize(file, fileName)
	@tokenOutputFile = File.new(fileName.split(".")[0] + "T.xml", "w")
	self.analysizeFile(file)
end

def analysizeFile(file)
	file = file.gsub(/((?:\/\*(?:[^*]|(?:\*+[^*\/]))*\*+\/)|(?:\/\/.*))/, '').split.join(' ') #删除所有注释
	puts "remove comments:"
	puts file
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


