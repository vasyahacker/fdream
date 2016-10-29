# -*- coding: utf-8 -*-

###################
#Data base manager#
###################

class MUDDB
  def initialize()
    @db = SQLite3::Database.new('db/sity.db')
    @transaction_active = false
  end

  def upgrade()

#    	insert into locations(name, descr,n,s,w,e,u,d) values ( 'room', 'my room - big room', 2, 0 ,0, 0, 0, 0 );
#    	insert into locations(name, descr,n,s,w,e,u,d) values ( 'hole', 'hole room', 0, 1 , 0, 0, 0, 0 );
#		alter table chars add isonline varchar2(9);
#		alter table chars add descr text;
#		alter table chars add status text;
#		update chars set isonline='false';
#		delete from chars where name_komu='noname';
#		alter table chars add name_chey varchar2(30);
#		alter table chars add sensibleness integer;
#		alter table chars add lastlogin integer;
#		alter table chars add createdate integer;
#		alter table objects add number_of_uses integer;
#		alter table chars add realemail varchar2(64);
#		alter table locations add power_place varchar2(9);
#		alter table objects add adjectives text;
#		alter table objects add descr text;
#		alter table locations add code text;
#		alter table objects add id_owner integer;
#		update objects set id_owner=0;
#       alter table chars add pwd varchar2(18);
    sql = <<SQL
		create table if not exists knownlocations(
			id_player integer,
			id_location integer
		);
		
		create table if not exists objects(
    	    id integer PRIMARY KEY AUTOINCREMENT,
			type varchar2(18),
			names varchar2(513),
			data text,
			descriptions text,
			static varchar2(9),
			id_parent integer,
			parent_type varchar2(27),
			number_of_uses integer,
			code text,
      adjectives text,
      descr text,
      id_owner integer
		);
			
		create table if not exists levents(
    	    id integer PRIMARY KEY AUTOINCREMENT,
			id_location integer,
			times integer,
			descr varchar2(2048)
		);

SQL

    @db.execute_batch(sql);
  end

  def create()

    sql = <<SQL

    	create table if not exists chars (
    	    id integer PRIMARY KEY AUTOINCREMENT,
	    	addr varchar2(30) UNIQUE,
            name varchar2(30) UNIQUE,
            name_kogo varchar2(30),
            name_komu varchar2(30),
            name_kem varchar2(30),
            name_o_kom varchar2(30),
            sex varchar2(7),
            wher integer,
		    rights varchar2(15),
			isonline varchar2(9),
			descr text,
			status text,
			name_chey varchar2(30),
			state varchar2(279),
			sms text,
			sensibleness integer,
			lastlogin integer,
			createdate integer,
			realemail varchar2(64),
			pwd varchar2(18)
		 );
	
    	create table if not exists locations (
    	    id integer PRIMARY KEY AUTOINCREMENT,
    	    name varchar2(30),
		    descr text,
		    nid text,
		    sid text,
		    wid text,
		    eid text,
		    uid text,
		    did text,
	    	nod text,
		    sod text,
		    wod text,
		    eod text,
		    uod text,
		    dod text,
    	    n integer,
    	    s integer,
    	    w integer,
    	    e integer,
    	    u integer,
    	    d integer,
			owner_id integer,
			allow_random_enter varchar2(9),
			power_place varchar2(9),
      code text
    	);
        
    	
	create table if not exists descriptions(
	    name varchar2(30) unique,
	    descr text
	);

	create table if not exists socials(
	    name varchar2(30) unique,
	    descr text
	);
SQL
    @db.execute_batch(sql)
  end

  def safe_query(sql)
    while @transaction_active
      #   p "#{Time.now.to_s} жду завершения транзакции"
      sleep 0.3
    end
    @transaction_active = true
    @db.transaction
    @db.execute(sql)
    id = @db.last_insert_row_id
    @db.commit
    @transaction_active = false
    id
  end

###########
# OBJECTS #
###########
#def loadinventory(id)
#		@db.execute( "SELECT
#o.id,
#o.type,
#o.name
#FROM 
#objects o LEFT JOIN backpacks b ON o.id = b.id_object
#WHERE b.id_player=#{id.to_s};" )
#	end

  def addobject(o)
    id = safe_query("insert into objects(type,names,data,descriptions,static,id_parent,parent_type,number_of_uses,adjectives,descr,id_owner)
			values(
			    '#{quote(o.type)}',
			    '#{quote(o.names_string)}',
			    '#{quote(o.data)}',
			    '#{quote(o.descriptions)}',
			    '#{quote(o.static.to_s)}',
			    '#{o.id_parent}',
			    '#{quote(o.parent_type)}',
				   #{o.number_of_uses},
          '#{quote(o.adjectives)}',
          '#{quote(o.descr)}',
				   #{o.id_owner}          
      );")
    id
  end

  def updateobject(o)
    safe_query("update objects set
			type='#{quote(o.type)}',
			names='#{quote(o.names_string)}',
			data='#{quote(o.data.to_s)}',
			descriptions='#{quote(o.descriptions)}',
			descr='#{quote(o.descr)}',
			static='#{quote(o.static.to_s)}',
			id_parent='#{o.id_parent}',
			parent_type='#{quote(o.parent_type)}',
			number_of_uses=#{o.number_of_uses},
			code='#{quote(o.code)}',
			adjectives='#{quote(o.adjectives)}',
			id_owner=#{o.id_owner}
			where id=#{o.id};")
  end

  def deleteobject(id)
    safe_query("delete from objects where id=#{id.to_s};")
  end

  def loadobjects(idparent, parenttype)
    objects = []
    @db.execute("select * from objects where id_parent=#{idparent} and parent_type='#{parenttype}';") do |id, type, names, data, descriptions, static, id_parent, parent_type, number_of_uses, code, adjectives, descr, id_owner|

      case type
        when 'NPC'
          obj = NPC.new(names.force_encoding('utf-8'), type)
        when 'rune'
          obj = Rune.new(names.force_encoding('utf-8'), type)
        else
          obj = Obj.new(names.force_encoding('utf-8'), type)
      end
      obj.id = id.to_i
      obj.data = data.force_encoding('utf-8')
      obj.descriptions = descriptions.force_encoding('utf-8')
      obj.static = (static == 'true') ? true : false
      obj.id_parent = id_parent.to_i
      obj.parent_type = parent_type
      obj.number_of_uses = number_of_uses.to_i
      obj.code = code.force_encoding('utf-8') unless code.nil?
      obj.runfork() if obj.type=='NPC'
      obj.adjectives = adjectives.force_encoding('utf-8') unless adjectives.nil?
      obj.descr = descr.force_encoding('utf-8') unless descr.nil?
      obj.id_owner = id_owner.to_i
      objects.push(obj)
    end
    objects
  end

#######
# MAP #
#######	
  def lchownall(id1, id2)
    safe_query("update locations set owner_id=#{id2} where owner_id=#{id1}")
  end

  def lcount
    @db.get_first_value("select count(*) from locations").to_s.force_encoding('utf-8')
  end

  def loadmap()
    locations = []
    @db.execute("select * from locations") do |id, name, descr, nid, sid, wid, eid, uid, did, nod, sod, wod, eod, uod, dod, n, s, w, e, u, d, ownerid, areflag, power_place, code|
      l = Location.new(
          name.force_encoding('utf-8'), descr.force_encoding('utf-8'),
          nid.force_encoding('utf-8'), sid.force_encoding('utf-8'),
          wid.force_encoding('utf-8'), eid.force_encoding('utf-8'),
          uid.force_encoding('utf-8'), did.force_encoding('utf-8'),
          nod.force_encoding('utf-8'), sod.force_encoding('utf-8'),
          wod.force_encoding('utf-8'), eod.force_encoding('utf-8'),
          uod.force_encoding('utf-8'), dod.force_encoding('utf-8'),
          n.to_i, s.to_i, w.to_i, e.to_i, u.to_i, d.to_i)
      l.id = id.to_i
      l.areflag = (areflag == 'true') ? true : false
      l.objects = loadobjects(id.to_i, 'location')
      l.ownerid = ownerid.to_i
      l.power_place = (power_place == 'true') ? true : false
      l.code = code.force_encoding('utf-8') unless code.nil?
      loadlevents(l)
      locations[id.to_i] = l
    end
    locations
  end

  def loadknownlocs(id_player)
    knownlocs = Array.new
    @db.execute("select id_location from knownlocations where id_player=#{id_player}") do |id_location|
      knownlocs.push(id_location[0].to_i)
    end
    knownlocs
  end


  def addknownloc(p)
    safe_query("insert into knownlocations(id_player,id_location)
					  values(#{p.id}, #{p.where});")
  end

  def addlocation(l)
    safe_query("insert into locations(name,descr,
	      nid,sid,wid,eid,uid,did,
	      nod,sod,wod,eod,uod,dod,
	      n,s,w,e,u,d,owner_id,
			  allow_random_enter,power_place,code)
			  values('#{quote(l.name)}',
				  '#{quote(l.descr)}',
				  '#{quote(l.nid)}',
				  '#{quote(l.sid)}',
				  '#{quote(l.wid)}',
				  '#{quote(l.eid)}',
				  '#{quote(l.uid)}',
				  '#{quote(l.did)}',
				  '#{quote(l.nod)}',
				  '#{quote(l.sod)}',
				  '#{quote(l.wod)}',
				  '#{quote(l.eod)}',
				  '#{quote(l.uod)}',
				  '#{quote(l.dod)}',
				  #{l.n},#{l.s},#{l.w},#{l.e},#{l.u},#{l.d},
				  #{l.ownerid},
				  '#{quote(l.areflag.to_s)}',
				  '#{quote(l.power_place.to_s)}',
				  '#{quote(l.code)}' )
			  ")
  end

  def updatelocation(l)
    safe_query("update locations set
			  name='#{quote(l.name)}',
			  descr='#{quote(l.descr)}',
			  nid='#{quote(l.nid)}',
			  sid='#{quote(l.sid)}',
			  wid='#{quote(l.wid)}',
			  eid='#{quote(l.eid)}',
			  uid='#{quote(l.uid)}',
			  did='#{quote(l.did)}',
			  nod='#{quote(l.nod)}',
			  sod='#{quote(l.sod)}',
			  wod='#{quote(l.wod)}',
			  eod='#{quote(l.eod)}',
			  uod='#{quote(l.uod)}',
			  dod='#{quote(l.dod)}',
			  n=#{l.n},s=#{l.s},w=#{l.w},e=#{l.e},u=#{l.u},d=#{l.d},
			  owner_id=#{l.ownerid},
			  allow_random_enter='#{quote(l.areflag.to_s)}',
			  power_place='#{quote(l.power_place.to_s)}',
			  code='#{quote(l.code)}'
			  where id=#{l.id}")
  end

  def deletelocation(id)
    safe_query("delete from locations where id=#{id.to_s}")
    safe_query("delete from levents where id_location=#{id.to_s}")
  end

  def loadlevents(l)
    levents = []
    @db.execute("select * from levents where id_location=#{l.id.to_s}") do |id, lid, times, descr|
      l.addEvent(times.to_i, descr.force_encoding('utf-8'), id)
    end
    levents
  end

  def deletelevent(id)
    safe_query("delete from levents where id=#{id.to_s}")
  end

  def addlevent(idloc, times, descr)
    safe_query("insert into levents(id_location,times,descr)
					  values(#{idloc.to_s},#{times.to_s}, '#{quote(descr)}');")
  end

  def updatelevent(e)
    safe_query("update levents set
			times=#{e.times.to_s},
			descr='#{quote(e.descr)}'
			where id=#{e.id.to_s}")
  end

#########
# CHARS #
#########
  def loadchars()
    players = {}
    @db.execute("select * from chars") do |id, addr, name, kogo, komu, kem, okom, sex, where, rights, isonline, descr, status, chey, state, sms, sensibleness, lastlogin, createdate, realemail, pwd|
      players[addr] = Player.new(
          name.force_encoding('utf-8'),
          kogo.force_encoding('utf-8'), komu.force_encoding('utf-8'),
          kem.force_encoding('utf-8'), okom.force_encoding('utf-8'),
          chey.force_encoding('utf-8'), sex.force_encoding('utf-8'),
          (isonline=='true') ? true : false, where.to_i,
          rights, descr.force_encoding('utf-8'), status)

      players[addr].id = id.to_i
      players[addr].knownlocs = loadknownlocs(id)
      players[addr].inventory = loadobjects(id, 'player')
      players[addr].state = state.force_encoding('utf-8')
      if sms.split(')><(').class == Array
        smslist = sms.force_encoding('utf-8').split(')><(')
        smslist.each { |s| players[addr].sms.push s }
      end
      players[addr].sensibleness = sensibleness.to_i
      players[addr].lastlogin = lastlogin.to_i
      players[addr].createdate = createdate.to_i
      players[addr].realemail = realemail
      players[addr].addr = addr
      players[addr].pwd = pwd
    end
    players
  end

  def loadadmins()
    admins = []
    @db.execute("select id,addr,rights from chars where rights='admin'") do |id, addr, rights|
      admins[id.to_i] = addr if rights == 'admin'
    end
    admins.compact
  end

  def addplayer(sender, p)
    safe_query("insert into chars(addr,name,name_kogo,name_komu,name_kem,name_o_kom,sex,wher,rights,isonline,descr,status,name_chey,state,sms,sensibleness,lastlogin,createdate,realemail,pwd)
  			values(
			    '#{quote(sender)}',
			    '#{quote(p.name)}',
			    '#{quote(p.kogo)}',
			    '#{quote(p.komu)}',
			    '#{quote(p.kem)}',
			    '#{quote(p.okom)}',
			    '#{quote(p.sex)}',
			    #{p.where},
			    '#{quote(p.rights)}',
			    '#{p.ready.to_s}',
				'#{quote(p.descr)}',
			    '#{quote(p.status)}',
				'#{quote(p.chey)}',
				'#{quote(p.state)}',
				'#{quote(p.sms)}',
				'#{p.sensibleness}',
				'#{p.lastlogin}',
				'#{p.createdate}',
				'#{quote(p.realemail)}',
				'#{quote(p.pwd)}' );")
  end

  def updateplayer(sender, p)
    smslist=""
    if p.sms.class == Array
      smslist = p.sms * ")><(" if p.sms.size > 0
    end
    safe_query("update chars set
			  name='#{quote(p.name)}',
			  name_kogo='#{quote(p.kogo)}',
			  name_komu='#{quote(p.komu)}',
			  name_kem='#{quote(p.kem)}',
			  name_o_kom='#{quote(p.okom)}',
			  sex='#{quote(p.sex)}',
			  wher=#{p.where},
			  rights='#{quote(p.rights)}',
			  isonline='#{p.ready.to_s}',
			  descr='#{quote(p.descr)}',
			  status='#{quote(p.status)}',
			  name_chey='#{quote(p.chey)}',
			  state='#{quote(p.state)}',
			  sms='#{quote(smslist)}',
			  sensibleness=#{p.sensibleness},
			  lastlogin=#{p.lastlogin},
			  realemail='#{quote(p.realemail)}',
			  pwd='#{quote(p.pwd)}',
			  addr='#{quote(p.addr)}'
			  where id='#{p.id}';")
  end

  def deleteplayer(sender)
    safe_query("delete from chars where addr='#{sender}'")
  end

  def last(n)
    list = []
    i = 0
    @db.execute("select name,lastlogin from chars order by lastlogin DESC limit #{n};") do |n, t|
      list[i] = [n, t]
      i += 1
    end
    list
  end

################
# DESCRIPTIONS #
################
  def adddescription(n, d)
    safe_query("insert into descriptions values('#{quote(n)}',
								  '#{quote(d)}')")
  end

  def loaddescriptions()
    descr = {}
    @db.execute("select * from descriptions") do |n, d|
      descr[n] = d.force_encoding('utf-8')
    end
    descr
  end

  def updatedescription(n, d)
    safe_query("update descriptions set
				  descr='#{quote(d)}'
				  where name='#{quote(n)}'")
  end

  def deletedescription(n)
    safe_query("delete from descriptions where name='#{quote(n)}'")
  end

##########################################################################
##upgrade##
  def upgrade()

  end

##########
  def q(txt)
    begin
      s = "\n|"
      cols =@db.prepare(txt)
      cols.columns.each do |col|
        s+= " #{col} |"
      end
      s += "\n|"

      @db.execute(txt) do |r|
        cols.columns.each do |c|
          s += " #{r[c].to_s} |";
        end
        s += "\n\n"
      end
    rescue => detail
      return "error in sql query" + $!.to_s+detail.backtrace.join("\n")
    end
    s
  end

  def quote(s)
    s.force_encoding('utf-8').gsub(/\'/, "''") unless s == nil || s == []
  end

end
