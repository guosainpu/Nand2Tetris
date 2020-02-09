require_relative 'JackTokenizer'
#require_relative 'compilationEngine' 

def compileTokenflow(tokenier, outputfile)
	compilationEngine = compilationEngine.new(tokenier, outputfile)
	compilationEngine.compile()
end

# main 
file_name_or_dir_name = ARGV[0]

if File.file?(file_name_or_dir_name)
	# 翻译单个文件
	xml_file = File.new(file_name_or_dir_name.split(".")[0] + ".xml", "w")
	tokenier = JackTokenizer.new(File.read(file_name_or_dir_name), file_name_or_dir_name)
	#compileTokenflow(tokenier, xml_file)
elsif File.directory?(file_name_or_dir_name)
	# 翻译多文件
	Dir.foreach(file_name_or_dir_name) do |filename|
  		if filename.split(".")[1] == "jack"
			tokenier = JackTokenizer.new(File.read(filename), filename)
			compileTokenflow(tokenier, xml_file)
  		end
	end
end 



