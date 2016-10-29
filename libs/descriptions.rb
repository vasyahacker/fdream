# -*- coding: utf-8 -*-

################
# Descriptions #
################
class Descriptions
    def initialize(db)
		@db = db
		@data = @db.loaddescriptions
    end
    
    def[](index)
		if @data.key?(index)
	    	@data[index]
		else
	    	"\nKey #{index} want be created! ;-) (dedit #{index})"
		end
    end

    def []=(index, value)
		v = value.sub(/^\s/,"")
		if @data.key?(index)
	    	@db.updatedescription(index, v)
		else
	    	@db.adddescription(index, v)
		end
		@data[index] = v
    end
    
    def build(index,params = false)
		descr = self[index]
		return if descr.nil?
		descr += "(#{params})" if descr == "\nKey #{index} want be created! ;-) (dedit #{index})"
		if params.class == Array
			params.each_with_index { | param, i |
			descr = descr.gsub("<<#{i.to_s}>>", param) } if params
		else
			descr = descr.gsub("<<0>>", params) 
		end
		descr
    end
    
    def list
		l = self['list']
		@data.sort.each { |p| l+= "\n#{p[0]}: #{p[1]}\n" }
		l
    end


    def edit(str)
		key = str.scan(/^[a-zA-Z0-9]+/)[0]
		newvalue = str.sub( key,'' )
		return self[key] if newvalue == ""
		self[key] = newvalue
		self['ok']
    end

    def delete(name)
		@data.delete(name)
		@db.deletedescription(name)
		self['ok']
    end
	
	def present?(key)
		@data.key?(key)	
	end
end
