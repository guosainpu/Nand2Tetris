require_relative 'JackTokenizer'
require_relative 'CompilationEngine' 

# main 
file_name_or_dir_name = ARGV[0]

if File.file?(file_name_or_dir_name)
	# 翻译单个文件
	xml_file = File.new(file_name_or_dir_name.split(".")[0] + ".minexml", "w")
	tokenier = JackTokenizer.new(File.read(file_name_or_dir_name), file_name_or_dir_name)
	compilationEngine = CompilationEngine.new(tokenier, xml_file)
elsif File.directory?(file_name_or_dir_name)
	# 翻译多文件
	Dir.chdir(file_name_or_dir_name)
	puts Dir.pwd
	Dir.foreach(Dir.pwd) do |filename|
		nameSplit = filename.split(".")
  		if nameSplit.length == 2 && nameSplit[1] == "jack"
  			puts filename
  			xml_file = File.new(filename + ".minexml", "w")
			tokenier = JackTokenizer.new(File.read(filename), filename)
			compilationEngine = CompilationEngine.new(tokenier, xml_file)
  		end
	end
end 



