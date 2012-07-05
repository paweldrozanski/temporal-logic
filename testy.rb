require 'rubygems'
require "facets/string"
require 'tree'
require 'graphviz'
require 'ruby-prof'


class Parsing
	attr_accessor :table

	def initialize
		@table = Array.new
	end

	def recurse_parsing(formula)
		if not formula =~ /\&|\||\=/
			if formula =~ /\~/
				table.push("(")
				table.push(formula)
				table.push(")")
			else
				table.push(formula)
			end
			formula
		else
			formula = parse(formula)
			table.push("(")
			for i in 0..formula.length-1
				formula[i].replace(simplify(remove_spare_parenthesis(formula[i])))
				recurse_parsing(formula[i]) if not ['&', '|', '=>', '<=>'].include? formula[i]		
				table.push(formula[i]) if ['&', '|', '=>', '<=>'].include?(formula[i])
			end 
			table.push(")")
		end
	end
end

class Formula_Generator
	attr_accessor :formula, :level
	attr_reader :conjunction, :variable

	def initialize
		@conjunction = ['|', '&', '=>', '<=>'] #spójnik
		@variable = ['a', 'b', 'c', '~a', '~b', '~c'] #zmienna
		#@pref = ['~', '<>', '[]', '<>[]']
		formula = Array.new
	end

	def recurse_formula(lvl)
		if lvl==0
			"(#{@variable[Random.rand(@variable.length)]})"
		else
		 	# "(" << [recurse_formula(lvl-1), @variable[Random.rand(@variable.length)]].sample  << ")" << @conjunction[Random.rand(@conjunction.length)] << "(" << [recurse_formula(lvl-1), @variable[Random.rand(@variable.length)]].sample << ")"
		 	"(#{[recurse_formula(lvl-1), @variable[Random.rand(@variable.length)]].sample})#{@conjunction[Random.rand(@conjunction.length)]}(#{[recurse_formula(lvl-1), @variable[Random.rand(@variable.length)]].sample})"
		 	#["~(" << recurse_formula(lvl-1) << ")", "(" << recurse_formula(lvl-1) << ")", "~(" << @variable[Random.rand(@variable.length)] << ")","(" << @variable[Random.rand(@variable.length)] << ")"].sample
		end
	end
	def str(character)
		"(#{@variable[Random.rand(6)]})"
	end
end

class TNode
	attr_accessor :current, :next

	def initialize(c, n)
		@current = c
		@next = n
	end

	def get_current
		@current
	end
end

def in23(formula)
	#p "FORMULA IN23: #{formula}"

	#formula = formula.gsub(/ /,'').shatter(/\||\&|\<\=\>|\=\>/)
	formula.gsub!(/ /,'')
	formula = formula.shatter(/\||\&|\<\=\>|\=\>/)
	new_formula = Array.new
	tmp_formula = String.new
	number_of_parentheses = 0
	in_parentheses = false

	for index in 0..formula.length-1
		if formula[index] =~ /\(/ and in_parentheses == false
			in_parentheses = true
		end
		if in_parentheses == false
			new_formula.push(formula[index])
		end
		if in_parentheses == true
			if formula[index] =~ /\(|\)/
				for i in 0..formula[index].length-1
					number_of_parentheses = number_of_parentheses + 1 if formula[index][i] == '('
					number_of_parentheses = number_of_parentheses - 1 if formula[index][i] == ')'
				end
				tmp_formula.concat(formula[index])
			else
				tmp_formula.concat(formula[index])
			end
			if number_of_parentheses == 0
				new_formula.push(tmp_formula)
				tmp_formula = ''
				in_parentheses = false
			end
		end
	end
	# p "IN23 NEW FORMULA #{new_formula}"
	# p new_formula.length
	return new_formula
end

def atomized(single_formula)
	if single_formula =~ /\||\&|\=/
		return false
	else return true
	end
end

def prefix_and_formula(formula)
	# if not formula[0] == '~' and not formula[0] == '<' and not formula[0] == '['
	# 	return {"prefix" => '', "formula" => formula}
	# else
	# 	if formula =~ /\(/
	# 		new_formula = /\(.*/.match(formula)[0]
	# 		new_prefix = formula.gsub(/\(.*/, '')
	# 		return {"prefix" => new_prefix, "formula" => new_formula}
	# 	else
	# 		return {"prefix" => '', "formula" => formula}
	# 	end
	# end
	prefix = formula.scan(/^[~<>\[\]]+/).join
 	formula = formula.gsub(/^[~<>\[\]]+/, "")
 	#p "PREFIX: #{prefix} FORMULA: #{formula}"
 	return {"prefix" => prefix, "formula" => formula}
end

def parse(formula)
	#formula = formula.gsub(/ /,'')
	#formula = remove_spare_parenthesis(simplify(formula))

	#formula.replace(simplify(remove_spare_parenthesis(formula)))

	prefix = prefix_and_formula(formula)["prefix"]
	formula = prefix_and_formula(formula)["formula"]


	#p "--------------------- PARSE PREFIX #{prefix}"
	#p "--------------------- PARSE FORMULA #{formula}" 

	temp_in23 = in23(remove_spare_parenthesis(simplify(formula)))

	#p "TEMP_IN23: #{temp_in23}"


	if prefix == "~" #negacja formuly
		if atomized(formula)
			["#{prefix}#{temp_in23[0]}"]
		else
			return ["#{prefix}#{temp_in23[0]}", "&", "#{prefix}#{temp_in23[2]}"] if temp_in23[1] == '|'
			return ["#{prefix}#{temp_in23[0]}", "|", "#{prefix}#{temp_in23[2]}"] if temp_in23[1] == '&'
			return ["#{temp_in23[0]}", "&", "#{prefix}#{temp_in23[2]}"] if temp_in23[1] == '=>'
			return ["#{temp_in23[0]}&(~#{temp_in23[2]})", "|", "#{temp_in23[2]}&(~#{temp_in23[0]})"] if temp_in23[1] == '<=>'
		end

	elsif prefix =~ /\<|\[/ #temporalny prefix

		######################### piece of really sad code...
		
		if ['<>', '[]', '<>[]', '[]<>', '<>[]<>', '[]<>[]'].include?(prefix)  #prefix <> lub [] -> przepisywanie prefixu z formula
			atomized(formula) ? ["#{prefix}#{formula}"] : ["#{prefix}#{temp_in23[0]}", temp_in23[1], "#{prefix}#{temp_in23[2]}"]
		elsif prefix == '~<>' #zaprzeczenie <>
			raise "not implemented #{prefix}" 
		elsif prefix == '~[]'
			raise "not implemented #{prefix}" 
		elsif prefix == '<>~'
			raise "not implemented #{prefix}" 
		elsif prefix == '[]~'
			raise "not implemented #{prefix}" 
		elsif prefix == '~<>~'
			raise "not implemented #{prefix}" 
		elsif prefix == '~[]~'
			raise "not implemented #{prefix}" 
		elsif prefix == '~<>[]'
			raise "not implemented #{prefix}" 
		elsif prefix == '~[]<>'
			raise "not implemented #{prefix}" 
		elsif prefix == '[]~<>'
			raise "not implemented #{prefix}" 
		elsif prefix == '<>~[]'
			raise "not implemented #{prefix}" 
		elsif prefix == '[]<>~'
			raise "not implemented #{prefix}" 
		elsif prefix == '<>[]~'
			raise "not implemented #{prefix}" 
		elsif prefix == '~<>~[]'
			raise "not implemented #{prefix}" 
		elsif prefix == '~<>[]~'
			raise "not implemented #{prefix}" 
		elsif prefix == '~<>~[]~'
			raise "not implemented #{prefix}" 
		elsif prefix == '~[]~<>'
			raise "not implemented #{prefix}" 
		elsif prefix == '~[]<>~'
			raise "not implemented #{prefix}" 
		elsif prefix == '~[]~<>~'
			raise "not implemented #{prefix}" 
		end

	
	else #brak spojnika
		#TODO
		if atomized(formula)
			["#{temp_in23[0]}"]
		else
			# raise "NOT IMPLEMENTED TRIVIAL SITUATION"
			#temp_in23
			if temp_in23[1] == '=>'
				["~#{temp_in23[0]}", "|", "#{temp_in23[2]}"]
			elsif temp_in23[1] == '<=>'
				["#{temp_in23[0]}=>#{temp_in23[2]}", "&", "#{temp_in23[2]}=>#{temp_in23[0]}"]
			else
				temp_in23
			end

		end

	end



	# elsif atomized(formula)
	# 	return prefix << formula

	# #temporalne prefiksy
	# if prefix == "~<>"
	# 	parsed_formula = parse("~#{formula}")
	# 	return ["[]#{parsed_formula[0]}", parsed_formula[1], "[]#{parsed_formula[2]}"] if not parsed_formula[2].nil?
	# 	return ["[]#{parsed_formula[0]}"]

	# elsif prefix == "~[]"
	# 	parsed_formula = parse("~#{formula}")
	# 	return ["<>#{parsed_formula[0]}", parsed_formula[1], "<>#{parsed_formula[2]}"] if not parsed_formula[2].nil?

	# elsif prefix == "~<>[]"
	# 	parsed_formula = parse("~#{formula}")
	# 	return ["[]<>#{parsed_formula[0]}", parsed_formula[1], "[]<>#{parsed_formula[2]}"] if not parsed_formula[2].nil?
	
	# elsif prefix == "~[]<>"
	# 	parsed_formula = parse("~#{formula}")
	# 	return ["<>[]#{parsed_formula[0]}", parsed_formula[1], "<>[]#{parsed_formula[2]}"] if not parsed_formula[2].nil?

	# elsif prefix == "<>~[]"
	# 	parsed_formula = parse("~#{formula}")
	# 	return ["<><>#{parsed_formula[0]}", parsed_formula[1], "<><>#{parsed_formula[2]}"] if not parsed_formula[2].nil?

	# elsif prefix == "[]~<>"
	# 	parsed_formula = parse("~#{formula}")
	# 	return ["[][]#{parsed_formula[0]}", parsed_formula[1], "[][]#{parsed_formula[2]}"] if not parsed_formula[2].nil?
	
	# elsif prefix == "<>~<>"
	# 	parsed_formula = parse("~#{formula}")
	# 	return ["<>[]#{parsed_formula[0]}", parsed_formula[1], "<>[]#{parsed_formula[2]}"] if not parsed_formula[2].nil?			

	# elsif prefix == "[]~"
	# 	if atomized(formula)
	# 		#p p "---------------------------------- ERROR ------------------------------ #{prefix} -- #{formula}"	
	# 		return formula
	# 	else
	# 	p "BLEDNA FORMULA: #{formula}"
	#  	parsed_formula = parse("~#{formula}")

	#  	p "TO JEST BLAD -> #{parsed_formula}"
	#  	return ["[]#{parsed_formula[0]}", parsed_formula[1], "[]#{parsed_formula[2]}"] if not parsed_formula[2].nil?	
	 	
	#  end

	# elsif prefix == "<>~"
	# 	if atomized(formula)
	# 		return formula
	# 	else
	#  	parsed_formula = parse("~#{formula}")
	#  	return ["<>#{parsed_formula[0]}", parsed_formula[1], "<>#{parsed_formula[2]}"] if not parsed_formula[2].nil?			
	#  end

	# elsif prefix == "<>[]~"
	#  	prefix = "<>[]"
	#  	parsed_formula = parse("~#{formula}")
	#  	return ["<>[]#{parsed_formula[0]}", parsed_formula[1], "<>[]#{parsed_formula[2]}"] if not parsed_formula[2].nil?

	# elsif prefix == "[]<>~"
	#  	prefix = "<>[]"
	#  	parsed_formula = parse("~#{formula}")
	#  	return ["[]<>#{parsed_formula[0]}", parsed_formula[1], "[]<>#{parsed_formula[2]}"] if not parsed_formula[2].nil?			
	

	# elsif not prefix =~ /\~/ and prefix =~ /\<|\[/
	# 		p "temporalny spojnik bez zaprzeczenia"
	# 		parsed_formula = parse(formula)
	# 		["#{prefix}(#{parsed_formula[0]})", parsed_formula[1], "#{prefix}(#{parsed_formula[2]})"] if not parsed_formula[2].nil?
	# 		return ["#{prefix}(#{parsed_formula[0]})", parsed_formula[1], "#{prefix}(#{parsed_formula[2]})"] if not parsed_formula[2].nil?			


	# #if formula[0] == '~' and formula[1] == '('
	# elsif prefix == '~'
	# 	#p "negacja formuly"
	# 	#puts "SLiCE:", formula = formula.slice(2..-2)
	# 	formula = formula.slice(1..-2) if formula.length>2
	# 	# p "SLICE: #{formula}"

	# 	formula = in23(formula)
	# 	# p "IN23: #{formula}"

	# 	if formula[1] == "&"
	# 		return ["~#{formula[0]}", "|", "~#{formula[2]}"]

	# 	elsif formula[1] == "|"
	# 		return ["~#{formula[0]}", "&", "~#{formula[2]}"]

	# 	elsif formula[1] == "=>"
	# 		return [formula[0], "&", "~#{formula[2]}"]

	# 	elsif formula[1] == "<=>"
	# 		p "ROWNOWAZNOSC ZAPRZECZONA"
	# 		return ["#{formula[0]}&(~#{formula[2]})", "|", "(~#{formula[0]})&#{formula[2]}"]

	# 	elsif formula.length == 1
	# 		return "~" + formula.join

	# 	end

	# else
	# 	#brak negacji
	# 	p "BRAK NEGACJI"
	# 	#formula = in23(formula)
	# 	new_formula = in23(formula)
	# 	p "NOW FORMULA #{new_formula}"

	# 	#new_array_formula = Array.new
	# 	#if formula[1] == "=>"
	# 	if new_formula[1] == "=>"

	# 		return ["#{prefix}~#{new_formula[0]}", "|", "#{prefix}#{new_formula[2]}"]
	# 		#p formula[1]
	# 	elsif new_formula[1] == "<=>"
	# 		p "ROWNOWAZNOSC"
	# 		return ["#{prefix}(#{new_formula[0]}&#{new_formula[2]})", "|", "#{prefix}(~#{new_formula[0]})&(~#{new_formula[2]})"]
	# 		#= ["" + formula[0].to_s + "=>" + formula[2].to_s + "", "&", "" + formula[2].to_s + "=>" + formula[0].to_s + ""]
	# 		#p formula[1]
	# 	else 
	# 		p "UKRYTA FORMULA: #{new_formula}"
	# 		return ["#{prefix}#{new_formula[0]}", new_formula[1], "#{prefix}#{new_formula[2]}"]
	# 	end
	# end
end

def count_parentesis(formula, start=0)
	#liczy ilość nawiasów począwszy od pozycji start=0	
	parenthesis_number = 0

	for element in start..formula.length-1-start
		if formula[element] == ")"
			parenthesis_number = parenthesis_number - 1
		elsif formula[element] == "("
			parenthesis_number = parenthesis_number + 1
		end

		if parenthesis_number < 0
			break
		end
	end
	parenthesis_number
end

def simplify(single_formula)
	# p "NOT YET SIMPLIFIED FORMULA: #{single_formula}"
	#uproszczenie formuły
	single_formula.gsub!(/~~/,"")
	single_formula.gsub!(/\<\>\<\>/,"<>")
	single_formula.gsub!(/\[\]\[\]/,"[]")
	single_formula.gsub!(/\<\>\[\]\<\>\[\]/, "<>[]")
	single_formula.gsub!(/\[\]\<\>\[\]\<\>/,"[]<>")
	# p "SIMPLIFIED FORMULA: #{single_formula}"
	return single_formula
end

def remove_spare_parenthesis(single_formula)
	#p single_formula
	# p "NOT YET REMOVED PARENTHSIS: #{single_formula}"
	while single_formula[0] == '(' and single_formula[-1] == ')' and count_parentesis(single_formula,1) >= 0 do
		single_formula = single_formula.slice(1..-2)
	end

	if not single_formula =~ /\||\&|\=/ and atomized(single_formula)
	 	#usunięcie nawiasów
	 	#single_formula = single_formula.gsub("(","").gsub(")","")
	 	single_formula.gsub!(/\(|\)/, "")
	end
	# p "NOT YET REMOVED PARENTHSIS: #{single_formula}"
	single_formula
end

def paint_tree(tree)

	g = GraphViz.new( :G, :type => :"strict digraph" )

	tree.each{|node|
		g.add_nodes(node.name).label=node.content.current if not node.content.current.nil?
	}

	tree.each{|node|
		node.children {|child| g.add_edges(node.name, child.name) } 
	}

	g.output(:png => "./public/images/formula.png")
end

def true_array(array)
	tmp_array = array.uniq
	result = false
	tmp_array.each {|atom| result = true if tmp_array.include?("~" << atom)}	
	result
end

def make_tree_of_formula(formula)

	list2parse = Array.new


	r_node = Tree::TreeNode.new("ROOT",TNode.new(nil, nil)) 
	r_node << Tree::TreeNode.new("1", TNode.new(formula, nil))


	list2parse.push(r_node["1"])

	while !list2parse.empty?
		3.times {puts}

		tmp_r_node = list2parse.shift.dup
		p "CURRENT"
		p tmp_r_node.content.current
		p "NEXT"
		p tmp_r_node.content.next
		p "PARSED"
		p parsed = parse(tmp_r_node.content.current)

		if parsed.length == 3 and parsed[1] == '&' #sparsowana formula dlugosci 3 oraz koniunkcja w srodku
			#raise "3&"
			tmp_current = parsed[0] #p
			tmp_next = parsed[2] #q
			tmp_id = tmp_r_node.name.dup << "1" #id

			treenode = Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next]))

			r_node.each_leaf {|leaf| leaf << treenode if (leaf.name == tmp_r_node.name)	}

			list2parse = [treenode, *list2parse]

		elsif parsed.length == 3 and parsed[1] == '|' #sparsowana formula dlugosci 3 oraz koniunkcja w srodku
			#raise "3|"
			tmp_current1 = parsed[0]
			tmp_current2 = parsed[2]
			#nie potrzeba definiowac nastepnego elementu
			tmp_id1, tmp_id2 = tmp_r_node.name.dup << "1", tmp_r_node.name.dup << "2"

			treenode1 = Tree::TreeNode.new(tmp_id1, TNode.new(tmp_current1, [*tmp_r_node.content.next])) #?????
			treenode2 = Tree::TreeNode.new(tmp_id2, TNode.new(tmp_current2, [*tmp_r_node.content.next])) #?????

			r_node.each_leaf {|leaf| begin
				leaf << treenode1
	 			leaf << treenode2
	 		end if (leaf.name == tmp_r_node.name)	}

	 		#dodawanie wierzchołków do listy parsingowej
	 		list2parse = [treenode1, treenode2,  *list2parse]


		
		elsif parsed.length == 1
			
			if tmp_r_node.content.next[0].nil?
				#TODO dla logiki temporalnej: <>p -> p
			else
				#nastepnik nie jest nil = zostaly jakies formuly do rozkladu
				tmp_current = tmp_r_node.content.next.shift #wyciagniecie pierwszej formuly z tmp_r_node.content.next
				#nie potrzeba definiowac next
				tmp_id = tmp_r_node.name.dup << "1"

				treenode = Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [*tmp_r_node.content.next])) #?????

				r_node.each_leaf {|leaf| leaf << treenode if (leaf.name == tmp_r_node.name)	}

				list2parse = [treenode, *list2parse]

			end
			#raise "length = 1"
		end
			






		p "LISTA DO SPARSOWANIA"
		list2parse.each {|el| puts "Current: #{el.content.current}, Next: #{el.content.next}"}
	end
#----------------------------------------------------------------------------------------------------------------------------------------
	# while not list2parse.empty?
	# 	puts
	# 	tmp_r_node = list2parse.shift.dup
	# 	p "ZOSTANIE SPRASOWANE: #{tmp_r_node.content.current}"
	# 	parsed = parse(tmp_r_node.content.current)

	# 	p "SPARSOWANO:"
	# 	p parsed

	# 	if parsed.length == 3 and parsed[1] == '&' #sparsowana formula dlugosci 3 oraz koniunkcja w srodku
	# 		p "____length 3_____&_____"
	# 		tmp_current = parsed[0]
	# 		tmp_next = [parsed[2], *tmp_r_node.content.next] 
	# 		tmp_id = tmp_r_node.name.dup << "1"

	# 		treenode = Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next]))
	# 		r_node.each_leaf {|leaf| 
	# 			#leaf << Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next])) if (leaf.name == tmp_r_node.name)	
	# 			leaf << treenode if (leaf.name == tmp_r_node.name)
	# 		}

	# 		list2parse = [treenode, *list2parse]

	# 	elsif parsed.length == 3 and parsed[1] == '|'

	# 		#tworzenie nowego wierzchołka
	# 		tmp_current1 = parsed[0]
	# 		tmp_current2 = parsed[2]
	# 		tmp_next1 = tmp_next2 = tmp_r_node.content.next.nil? ? nil : tmp_r_node.content.next.dup
	# 		tmp_id1 = tmp_r_node.name.dup << "1"
	# 		tmp_id2 = tmp_r_node.name.dup << "2"

	# 		treenode1 = Tree::TreeNode.new(tmp_id1, TNode.new(tmp_current1, tmp_next1))
	# 		treenode2 = Tree::TreeNode.new(tmp_id2, TNode.new(tmp_current2, tmp_next2))

	# 		#dodawanie wierzchołka do drzewa
	# 		r_node.each_leaf {|leaf| 
	#  			begin
	#  				leaf << treenode1
	#  				leaf << treenode2
	#  			end if (leaf.name == tmp_r_node.name)	}

	#  		#dodawanie wierzchołków do listy parsingowej
	#  		list2parse = [treenode1, treenode2,  *list2parse]

	# 	elsif parsed.length == 1
	# 		# raise 'not yet implemented exception'
	# 		if prefix_and_formula(parsed[0])["prefix"] =~ /\<|\[/ #temporalny prefix przed atomem
				 
	# 			#raise "length 1 and temporal prefix"

	# 			tmp_current = prefix_and_formula(parsed[0])["formula"]
	# 			tmp_next = tmp_r_node.content.next
	# 			tmp_id = tmp_r_node.name.dup << "1"

	# 			treenode = Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next]))

	# 			r_node.each_leaf {|leaf| 
	# 			#leaf << Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next])) if (leaf.name == tmp_r_node.name)	
	# 				leaf << treenode if (leaf.name == tmp_r_node.name)
	# 			}

	# 			list2parse = [treenode, *list2parse]

				

	# 		elsif prefix_and_formula(parsed[0])["prefix"] == '~' #zaprzeczenie przed atomem
	# 			# p "PREFIX: #{prefix_and_formula(parsed[0])["prefix"]}"
	# 			# p "FORMULA: #{prefix_and_formula(parsed[0])["formula"]}"
	# 			p "PARSED: #{parsed}"
	# 			#raise "length 1 and ~ prefix"


	# 		else
	# 			# raise "HERE!"
	# 			if not tmp_r_node.content.next.nil? #atom i niepusta lista następników
	# 				tmp_current = in23(tmp_r_node.content.next[0].dup).join
	# 				tmp_next = tmp_r_node.content.next.slice(1..-1)
	# 				tmp_id = tmp_r_node.name.dup << "1"

	# 				treenode = Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next]))	

	# 				r_node.each_leaf {|leaf| 
	# 				#leaf << Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next])) if (leaf.name == tmp_r_node.name)	
	# 				leaf << treenode if (leaf.name == tmp_r_node.name)
	# 				}

	# 				list2parse = [treenode, *list2parse]

	# 				#raise "no prefix"			
	# 			# else
	# 			# 	raise "completely different exception" #atom i brak następników (nil)
	# 			end
			
	# 		end

	# 	end
	# 	p "LISTA PARSINGOWA:"
	# 	list2parse.each {|el| p el.content.current}
	# end



	#-----------------------------------------------------------------------------------------------------------------------------------

	# 	p tmp_r_node = list2parse.shift.dup
	# 	5.times {puts}
	# 	parsed = parse(tmp_r_node.content.current)
	# 	p "PARSED: #{parsed}"
	# 	p "------------------BEFORE IF ------------------CURRENT #{tmp_r_node.content.current}-----NEXT #{tmp_r_node.content.next}---------------"
	# 	#p tmp_r_node.content.next
	# 	if  and parse(tmp_r_node.content.current)[1] == '&'



	# 		 p "------------------------- & -------------------------"
	# 		 tmp_current = parse(tmp_r_node.content.current)[0]
	# 		 tmp_next = parse(tmp_r_node.content.current)[2]
	# 		 tmp_id = tmp_r_node.name.dup << "1"

	# 		 p "&"
	# 		 p "TMP_CURRENT #{tmp_current} TMP_NEXT #{tmp_next} <--------------------------------------------"
 
	# 		 treenode = Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next]))
	# 		r_node.each_leaf {|leaf| leaf << Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, [tmp_next, *tmp_r_node.content.next])) if (leaf.name == tmp_r_node.name)	}

	# 		list2parse = [treenode, *list2parse]
	# 		 p "------------------------- end & -------------------------"

	# 	elsif parse(tmp_r_node.content.current)[1] == '|'
	# 		  "------------------------- | -------------------------"
	# 		 tmp_r_node.content

	# 		 tmp_current1 = parse(tmp_r_node.content.current)[0] #a
	# 		 tmp_current2 = parse(tmp_r_node.content.current)[2] #b
			
	# 		 tmp_next1 = tmp_next2 = tmp_r_node.content.next.nil? ? nil : tmp_r_node.content.next.dup
	# 		 p "|"
	# 		 p "TMP_CURRENT1 #{tmp_current1} TMP_NEXT1 #{tmp_next1} <--------------------------------------------"
	# 		 p "TMP_CURRENT2 #{tmp_current2} TMP_NEXT2 #{tmp_next2} <--------------------------------------------"

	# 		 tmp_id1 = tmp_r_node.name.dup << "1"
	# 		 tmp_id2 = tmp_r_node.name.dup << "2"

	# 		treenode1 = Tree::TreeNode.new(tmp_id1, TNode.new(tmp_current1, tmp_next1))
	# 		treenode2 = Tree::TreeNode.new(tmp_id2, TNode.new(tmp_current2, tmp_next2))

	# 		r_node.each_leaf {|leaf| 
	# 			begin
	# 				leaf << treenode1
	# 				leaf << treenode2
	# 			end if (leaf.name == tmp_r_node.name)	}

	# 		list2parse = [treenode1, treenode2,  *list2parse]

	# 		 "------------------------- end | -------------------------"
				
	# 	else
	# 		# "------------------------- ELSE -------------------------"
			
	# 		if not tmp_r_node.content.next.nil? and tmp_r_node.content.next.length >0

	# 		 	p "!!!!!!!!! START NOT NIL AND >0"
	# 		 	p "___________ NEXT NIL ___________ CURRENT: #{tmp_r_node.content.current} NEXT: #{tmp_r_node.content.next}"

	# 		 	p tmp_current = remove_spare_parenthesis(tmp_r_node.content.next[0]).dup
	# 		 	p tmp_next = tmp_r_node.content.next[1..-1] #if not tmp_r_node.content.next.nil?
	# 		 	p tmp_id = tmp_r_node.name.dup << "1"

	# 		 	p "TMP_CURRENT #{tmp_current1} TMP_NEXT #{tmp_next1} <--------------------------------------------"

	# 		 	p "!!!!!!!!! END NOT NIL AND >0"
			 	
	# 		 	treenode = Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, tmp_next))

	# 			r_node.each_leaf {|leaf| leaf << treenode if leaf.name == tmp_r_node.name	}

	# 			list2parse = [treenode, *list2parse]

	# 			# "--------- end ELSE ---------"
	# 		end

	# 		# if tmp_r_node.content.next == []
	# 		# 	#raise "NIL!"
	# 		# 	p "___________ NEXT NIL ___________ CURRENT: #{tmp_r_node.content.current} NEXT: #{tmp_r_node.content.next}"
	# 		# 	# raise "NiL!"
	# 		# 	if not tmp_r_node.content.current["formula"] =~ /\~/
	# 		# 		# raise "~"
	# 		# 		p tmp_current = prefix_and_formula(tmp_r_node.content.current)["formula"] 
	# 		# 	else
	# 		# 		# raise "no ~"
	# 		# 		p tmp_current = "~" << prefix_and_formula(tmp_r_node.content.current)["formula"] 
	# 		# 	end
	# 		# 	# raise 'poszlo'
	# 		#  	p tmp_next = nil
	# 		#  	tmp_id = tmp_r_node.name.dup << "1"

	# 		# 	treenode = Tree::TreeNode.new(tmp_id, TNode.new(tmp_current, tmp_next))
	# 		# 	r_node.each_leaf {|leaf| leaf << treenode if leaf.name == tmp_r_node.name	}

	# 		# end

	# 	end	
	# 	#r_node.print_tree
	# list2parse.each {|node| p "Current: #{node.content.current} Next: #{node.content.next}"}
	# end
	r_node
end

def make_and_paint(formula)
	p "make_tree_of_formula"; r_node = make_tree_of_formula(formula)
	p "paint_tree"; paint_tree(r_node)
	r_node
end

def branches(r_node)

	p "tworzenie!"

	paths = Array.new
	r_node.each_leaf{|leaf|
		array = []
			array << leaf.content.current
		leaf.parentage.each {|node| 
			array.push(node.content.current) if not node.content.current.nil?
		}
		# array.reverse
		paths << array
		array = []

	}

	return_paths = []
	paths.each {|path|
		lista = []
		path.each{|form| lista << form if not form =~ /\&|\||\=/ }
		if not true_array(lista.reverse.uniq)
			lista << 'g'
		else
			lista << 'r'
		end

		p "*********** LISTA *********"
		p lista
		#lista.each{|element| element.gsub!(/\[|\]|\<|\>/, '')}
		return_paths << lista

	}
	return_paths

end



	# output = Markaby::Builder.new(:indent=>1) do
	#   xhtml_strict do
	#     head { title "Temporal Logic in Ruby" }
	#     body do
	#       h1 "Logic formula: " << formula.to_s
	#       div do
	#         #p "Pierwszy akapit"
	#         strong "Branches of the formula:"
	#         div.spis! :style=>"color:red;font-weight:bolder" do
	#   			ul do
	#     			paths.each do |var|
	#     				lista = []
	#     				var.each{|form| lista << form if not form =~ /\&|\||\=/ }
	#       				if not true_array(lista.reverse.uniq)
	# 						li.branches lista.reverse.uniq , :style => "color: green"
	# 					else
	# 						li.branches lista.reverse.uniq , :style => "color: red"
	# 					end
	#       				p ''
	#     			end
	# 			  end
	# 		end
	#         #div { blockquote "a tu kawalek cytatu w div'e" }
	#       end
	#     end
	#   end
	# end

	# p output

	# aFile = File.new("testfile.html", "w")
	# aFile << output.to_s
	# aFile.close


# end

#TODO
#tree2graph -> metoda zamieniająca drzewo Tree na graf z pakietu Graphviz
#make_tree -> metoda tworząca drzewo Tree na podstawie zadanej formuły logicznej
#make_graph -> metoda tworząca graf na podstawie zadanej formuły

# levels = 7 #ilość poziomów spójników (...) spójnik (...) 

# p1 = Parsing.new
# stupid_formula = Formula_Generator.new
#result = RubyProf.profile do
#RubyProf.start
#p formula = stupid_formula.recurse_formula(levels)
#end
#example_formula = "~(((c)=>(~c))|(~b))"
#p1.recurse_parsing(example_formula).join




#p formula = "((a|b)&(b|c))&((b|(~c))&((~a)|c))"
#p formula = "(a|b)&(c|d)"
#p formula = 'a&(a|a)'
#p formula = "((~a)&((a|c)&((~c)|(~a))))"
#p formula = example_formula
#formula = "(~a)<=>a"
#formula = "~(p<=>q)"
#formula = "((a<=>b)<=>(c<=>a))"
#formula = "<>(a|b)=>[]b"
#formula = "((a<=>b)<=>(c<=>d))<=>((a<=>b)<=>(c<=>d))"
#formula = "(a|b)|(c|d)"

#p formula = "(((((~c)|(((a)=>((a)))<=>(a)))|(a))|((((b)<=>((~b)&((b))))<=>(b))|(~a)))<=>(((a)=>(c))|(~b))<=>((~a)<=>(~b)))<=>(((((~c)|(((a)=>((a)))<=>(a)))|(a))|((((b)<=>((~b)&((b))))<=>(b))|(~a)))<=>(((a)=>(c))|(~b))<=>((~a)<=>(~b)))"
#p formula = "(((((~c)|(((a)|((a)))|(a)))|(a))|((((b)|((~b)&((b))))|(b))|(~a)))|(((a)|(c))|(~b))|((~a)|(~b)))|(((((~c)|(((a)|((a)))|(a)))|(a))|((((b)|((~b)&((b))))|(b))|(~a)))|(((a)|(c))|(~b))|((~a)|(~b)))"
#p formula = "(((((~c)&(((a)&((a)))&(a)))&(a))&((((b)&((~b)&((b))))&(b))&(~a)))&(((a)&(c))&(~b))&((~a)&(~b)))&(((((~c)&(((a)&((a)))&(a)))&(a))&((((b)&((~b)&((b))))&(b))&(~a)))&(((a)&(c))&(~b))&((~a)&(~b)))"
#p formula = "(((((~c)|(((a)=>((a)))=>(a)))|(a))|((((b)=>((~b)&((b))))=>(b))|(~a)))=>(((a)=>(c))|(~b))=>((~a)=>(~b)))=>(((((~c)|(((a)=>((a)))=>(a)))|(a))|((((b)=>((~b)&((b))))=>(b))|(~a)))=>(((a)=>(c))|(~b))=>((~a)=>(~b)))"


#wysypuje sie
#p formula = "((((((~c)|(((a)&((a)))|(a)))|(a))|((((b)|((~b)&((b))))|(b))|(~a)))|(((a)&(c))|(~b))|((~a)|(~b)))|(((((~c)|(((a)&((a)))|(a)))|(a))|((((b)|((~b)&((b))))|(b))|(~a)))|(((a)&(c))|(~b))|((~a)|(~b))))&((((((~c)|(((a)&((a)))|(a)))|(a))|((((b)|((~b)&((b))))|(b))|(~a)))|(((a)&(c))|(~b))|((~a)|(~b)))|(((((~c)|(((a)&((a)))|(a)))|(a))|((((b)|((~b)&((b))))|(b))|(~a)))|(((a)&(c))|(~b))|((~a)|(~b))))"

#formula = "(c)&((b)<=>((~b)<=>(a)))"
# p formula = "(((a)=>(c))|(~b))<=>((~a)<=>(~b))"
#formula = "((((b)&(a))&((((((b)|(((~a)|(c))|(c)))|(~b))&((c)&(~a)))|(((~c)|((b)|((b)&(c))))|(~a)))|(~a)))&(((~b)|((~a)|(b)))|(((~c)|((((((((b))|(~a))|(c))|((((a))&(~b))|(~a)))&(((c)|(~c))&((~a)|(a))))|((c)&(b)))|(~a)))|((~a)|(b)))))&((((b)&(a))&((((((b)|(((~a)|(c))|(c)))|(~b))&((c)&(~a)))|(((~c)|((b)|((b)&(c))))|(~a)))|(~a)))&(((~b)|((~a)|(b)))|(((~c)|((((((((b))|(~a))|(c))|((((a))&(~b))|(~a)))&(((c)|(~c))&((~a)|(a))))|((c)&(b)))|(~a)))|((~a)|(b)))))"
#formula = "((~a)&(((((~c)&(~c))|(((c)&((b)&((c)&(~c))))&(b)))|(~c))|(((((a)&((b)&(a)))&(c))|(a))&(~a))))&(((a)&((~a)&((((~a)&(a))&((a)&((a)|(c))))&((((~b)|((((a))&(~a))&((~c)|(~b))))&(((((b))&((~a)))&(((a))|((b))))&(c)))|(~c)))))|(c))"
#formula = "((~a)|(c))&((((((b)&((((~b)|((~a)|((~a))))|(~b))|(((~b)|(~a))|(~c))))|(~c))&((((((c)|(b))|(a))|((~c)|((~b)|(((a))&((~c))))))&((b)&((a)&((~a)&(((c))|(c))))))&(~a)))&(~b))|(((b)&(~c))|(~a)))"
#p formula = "(a)&(((b)|((a)&(~b)))&(((b)|((((~a)&(~b))&(a))|(c)))|((a)|((((((~a)&(~c))|((a)|(((c))&((c)))))|(~a))&((~c)|((~a)|(~a))))&((a)|(((((a)&((~c)))&((~a)|((~c))))|((b)|(((~a))&(a))))|(~a)))))))"
#p formula = "(((((b)&((~b)|(a)))&(c))|(~b))&((b)|(~b)))&((b)&(((((b)&((a)|(~c)))&(c))|(((((c)|((~a)&(((~a))|((~c)))))|(~b))|((~a)&((~c)|(c))))&(((((((~b))&((~c)))|(b))|(~b))|(((~c)|(~c))|((~c)|(((~b))&((a))))))|(~a))))&((~a)&(~a))))"
#p formula = "((((~c)|(b))&(~b))|((((b)|(~c))&(~b))&(((b)|(~a))|((c)&(c)))))&((((a)&(b))&((((c)&((~b)&(~a)))|(c))&(c)))&((((((~a)|(~a))&((((~b)&(~c))|(c))&(~b)))|(~c))&((a)|(c)))|(~a)))"

#RubyProf.start
# p "make_tree_of_formula"; r_node = make_tree_of_formula(formula)
#result = RubyProf.stop

#RubyProf.start
# p "paint_tree"; paint_tree(r_node)
#result = RubyProf.stop
#make_and_paint(formula)



# Print a flat profile to text
#printer = RubyProf::FlatPrinter.new(result)
#printer.print(STDOUT)