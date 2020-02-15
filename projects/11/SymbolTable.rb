
class SymbolTable
	def initialize()
		@classTable = {}
		@subroutineTable = {}
		@symbolTableDic = {"static" => @classTable, "field" => @classTable, "arg" => @subroutineTable, "var" => @subroutineTable}
		@segementDic = {"static" => "static", "field" => "field", "arg" => "argument", "var" => "local"}
		@symbolIndex = {"static" => 0, "field" => 0, "arg" => 0, "var" => 0}
	end

	def startSubroutine()
		@subroutineTable.clear() #清空subroutineTable，开始编译下一个方法
		@symbolIndex["arg"] = 0
		@symbolIndex["var"] = 0
	end

	def define(name, type, kind)
		puts "存入符号表, name:#{name}, type:#{type}, kind:#{kind}"
		symbolTable = @symbolTableDic[kind]
		symbolTable[name] = [type, kind, @symbolIndex[kind]]
		@symbolIndex[kind] = @symbolIndex[kind] + 1
	end

	def varCount(kind)
		count = 0
		@classTable.each do |name, values|
			if values[1] == kind
				count = count + 1
			end
		end
		@subroutineTable.each do |name, values|
			if values[1] == kind
				count = count + 1
			end
		end
		return count
	end

	def kindOf(name)
		valus = self.findSymbol(name)
		return @segementDic[valus[1]]
	end

	def typeOf(name)
		valus = self.findSymbol(name)
		return valus[0]
	end

	def indexOf(name)
		valus = self.findSymbol(name)
		return valus[2]
	end

	def findSymbol(name)
		if @subroutineTable.key?(name)
			return @subroutineTable[name]
		end

		if @classTable.key?(name)
			return @classTable[name]
		end

		return ["NONE", "NONE", "NONE"]
	end

	def printSymbols
		puts "classTable: #{@classTable}"
		puts "subroutineTable: #{@subroutineTable}"
		puts "symbolIndex: #{@symbolIndex}"
	end
end



