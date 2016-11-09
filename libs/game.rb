# -*- coding: utf-8 -*-
require 'net/smtp'
require 'iconv'
require "base64"
require "gmail"
#####################################
# NOTE: Game - main objects manager #
#####################################
class Game
  attr_accessor :players, :descr, :admins, :time, :db, :locations

  def indafork
    thread = Thread.new do
      sleep 1 #important line
#			dotime = Time.now.to_i + 60*36 
      loop do
        @gmut.synchronize do
          begin
#		if dotime <= Time.now.to_i
# 					  @players.each do | addr,p |
#						  if p.ready
#							p.
#						  end
#					  end
#					  dotime = Time.now.to_i + 60*36
#					end

            @players.each do |addr, p|
              if p.ready
                ev = @locations[p.where].getEvents
                if !ev.nil?
                  next if ev.size < 3
                  showtoall('noaddr', ev[rand(ev.size)-1], p.where)
                end
              end
            end
          rescue
            sendmess($MAINADDR, "error in location events fork:\n" + $!.to_s)
          end
        end
        sleep 9
      end
    end
  end

  def ParseCommands(sender, message)

  end

  def Target(sender, message)
    p = @players[sender]
    #l = @locations[p.where]
    sender2 = GetAddrByName(sender, message)
    if sender2 != false
      p2 = @players[sender2]
      return @descr.build("playernothere", [p2.chey]) if p.where != p2.where || !p2.ready
      return @descr['alreadytarget'] if p.target == sender2
      p.target = sender2
      out = TextBuild(@descr['TargetToPlayer'], p, p2)
      showtoall(sender, out[1], p.where, sender2)
      sendmess(sender2, out[2])
    else
      return @descr['unknownname']
    end
    out[0]
  end

  def Sleep(sender)
    p = @players[sender]
    l = @locations[p.where]
    out = TextBuild(@descr['sleep'], p)

  end

  def wakeup(sender)

  end

  def upgrade
    @descr['ok']
  end

  def telnetpwd(sender, message)
    p = @players[sender]
    p.pwd = Digest::MD5.hexdigest(message)
    @db.updateplayer(sender, p)
    @descr['ok']
  end

  def send_email(t, to_alias, s, m, file)
    thread = Thread.new do
      begin
        gmail = Gmail.new($SMTP_LOGIN, $SMTP_PWD)
        email = gmail.deliver do
          to t
          subject s
          body m
          add_file file unless file.nil?
        end
      rescue
        sendmess($MAINADDR, "Ошибка при отсылке почты: #{$!.to_s}")
      end
    end
    nil
  end

  def playeremail(sender, message)
    p = @players[sender]
    return "email: #{p.realemail}" if message.nil?
    case message
      when /^([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/
        p.tmpemail = message
        p.confirmemailcode = rand(9999)
        msg = "Здравствуйте. Письмо сгенерированно для подтверждения владельца этого адреса и его использования в игре для пересылки сообщений.

Ваш код #{p.confirmemailcode.to_s}

Для активации введите команду 'myrealemail #{p.confirmemailcode.to_s}'"

        send_email(message, p.komu, 'Код подтверждения', msg, nil)
        return 'На указанный вами почтовый адрес выслан код активации. После получения кода введите команду "myrealemail код"'
      when /^[0-9]{1,5}$/
        return "Сначала укажите почтовый адрес." if p.tmpemail.nil?
        return "Не верный код подтверждения." unless message.to_i == p.confirmemailcode
        p.realemail = p.tmpemail
        p.confirmemailcode = nil
        p.tmpemail = nil
        @db.updateplayer(sender, p)
        return "Ваш адрес подтвержден. Спасибо!"
      else
        return @descr['error']
    end
  end

  def getplayerbyid(id)
    @players.each { |a, p| return p if p.id == id }
    return nil
  end

  def sendmess(sender, message)
    return if sender.class == NPC || $DreamInDream.include?(sender)
    @sys_send.call(sender, message)
  end

  def objectcode(sender, message)
    p = @players[sender]
    l = @locations[p.where]
    inv = p.inventory
    return @descr['youareempty'] if inv.empty?
    case message
      when /^[0-9]{1,3}$/i
        id = message.to_i
        return @descr['badnum'] if inv.size < id || id == 0
        return "\nRuby code for object \"#{inv[id-1].KtoChto}\":\n" + inv[id-1].code
      when /^([0-9]{1,3})\s(.+)$/m
        id = $1.to_i
        code = $2
        return @descr['badnum'] if inv.size < id || id == 0
    end
    inv[id-1].code = code
    inv[id-1].runfork

    @db.updateobject(inv[id-1])
    @descr['ok']

  end

  def getplayeraddress(name)
    sender2 = GetAddrByName('none', name)
    return @descr['unknownname'] unless sender2
    return sender2
  end

  def getplayerinfo(name)
    sender2 = GetAddrByName('none', name)
    return @descr['unknownname'] unless sender2
    playerinfo(sender2)
  end

  def playerinfo(sender)
    p = @players[sender]
    return @descr.build('playerinfo',
                        [p.name, @descr[p.sex],
                         Time.at(p.createdate).to_s,
                         p.descr, p.sensibleness.to_s,
                         Time.at(p.lastlogin).to_s
                        ])
  end

  def sms2all(sender, message)
    p = @players[sender]
    out = TextBuild(@descr.build('smssend2all', message), p)
    return @descr['error'] unless out.class == Array
    sendmess(sender, out[0])
    showtoall(sender, out[1], p.where)
    thread = Thread.new do
      begin
        @players.each do |sender2, p2|
          p2.sms.insert(0, "#{Time.now.to_s}\n#{out[3]}")
          @db.updateplayer(sender2, p2)
          sendmess(sender2, out[2]) if p2.ready &&
              p2.inventory.index { |o| o.type=='mobile' } != nil
        end
      rescue
        sendmess($MAINADDR, "Ошибка при отсылке смс: #{$!.to_s}")
      end
    end
    nil
  end

  def SMS(sender, message)
    if (sender.class == NPC)
      p = sender
    else
      p = @players[sender]
      if p.inventory.index { |o| o.type=='mobile' } == nil
        return @descr['smsnomobile']
      end
    end

    case message
      when nil
        return @descr['smsnosms'] if p.sms.empty?
        sms = p.sms.pop
        out = TextBuild(@descr.build('smslook', [sms, p.sms.size.to_s]), p)
        showtoall(sender, out[1], p.where)
        @db.updateplayer(sender, p)
        return out[0]
      when /^(#{USER_NAME_REGEX}):(.+)$/m
        sms = $2
        sender2 = GetAddrByName(sender, $1)
        return @descr['unknownname'] unless sender2
        p2 = @players[sender2]
        out = TextBuild(@descr.build('smssend', [sms]), p, p2)
        return @descr['error'] unless out.class == Array
        p2.sms.insert(0, "#{Time.now.to_s}\n#{out[3]}")
        send_email(p2.realemail, p2.komu, 'from dream', out[3], nil) if p2.realemail != nil &&
            p2.realemail.size > 5 && p2.ready == false

        @db.updateplayer(sender2, p2)
        showtoall(sender, out[1], p.where)
        sendmess(sender2, out[2]) if p2.ready &&
            p2.inventory.index { |o| o.type=='mobile' } != nil

        return out[0]
      else
        return @descr['error']
    end
  end

  def levents(sender, message)
    p = @players[sender]
    l = @locations[p.where]
    return @descr['locaccessdenied'] if !locrights?(p, l)
    return @descr['nosens'] if p.sensibleness < @need4eventloc
    out = ""
    case message
      when nil
        l.events.each_with_index do |e, i|
          out += "\n##{(i+1).to_s} Каждые #{e.times.to_s} мин: #{e.descr}"
        end
        return out
      when /^add\s([0-9]{1,2})\s(.+)$/m
        times = $1.to_i
        descr = $2.strip
        return @descr['error'] if times == 0 || descr.empty?
        lid = @db.addlevent(l.id, times, descr)
        l.addEvent(times, descr, lid)
      when /^del\s([0-9]{1,2})$/
        n = $1.to_i
        return @descr['error'] if l.events.size < n || l.events.size == 0
        @db.deletelevent(l.delEvent(n-1))
      when /^edit\s([0-9]{1,2})\s(.+)$/m
        n = $1.to_i
        return @descr['error'] if l.events.size < n || l.events.size == 0
        descr = $2.strip
        l.events[n-1].descr = descr
        @db.updatelevent(l.events[n-1])
      else
        return @descr['error']
    end
    @descr['ok']
  end

  def look2hands(sender, message)
    p = @players[sender]
    l = @locations[p.where]
    return @descr['thisactionnotneedhere'] if l.power_place
    return @descr['moresens'] if p.sensibleness > 99
    p.lrealise = @time
    out = TextBuild(@descr['look2hands'+rand(3).to_s], p)
    showtoall(sender, out[1], p.where)
    out[0]
  end

  def tongue2sky(sender)
    p = @players[sender]
    l = @locations[p.where]
    return @descr['thisactionnotneedhere'] if l.power_place
    return @descr['nosens'] if p.sensibleness < 100
    p.lrealise = @time
    out = TextBuild(@descr['tongue2sky'+rand(3).to_s], p)
#		showtoall(sender,out[1],p.where)
    out[0]
  end

  def lchown(sender, message)
    p = @players[sender]
    return @descr['nosens'] if p.sensibleness < @need
    l = @locations[p.where]
    all = false
    case message.strip
      when /^(#{USER_NAME_REGEX})$/m
        name = $1
      when /all\s(#{USER_NAME_REGEX})/i
        name = $1
        all = true
    end
    sender2 = GetAddrByName(sender, name)
    return @descr['unknownname'] unless sender2
    p2 = @players[sender2]
    if !all
      return @descr['locaccessdenied'] if !locrights?(p, l)
      l.ownerid = p2.id
      @db.updatelocation(l)
    else
      @locations.each_index do |id|
        unless @locations[id].nil?
          @locations[id].ownerid = p2.id if @locations[id].ownerid == p.id
        end
      end
      @db.lchownall(p.id, p2.id)
    end
    @descr['ok']
  end

  def Return(sender, message)
    p = @players[sender]
    l = @locations[p.where]
    return @descr['error'] if p.where == RETURN_LOCATION
    moveplayers(sender, p.where, RETURN_LOCATION, sender)
    nil
  end

  def ObjectDelete(sender, message)
    id = message.to_i
    p = @players[sender]
    l = @locations[p.where]
    inv = p.inventory
    return @descr['youareempty'] if inv.empty?
    return @descr['badnum'] if inv.size < id || id == 0
    @db.deleteobject(inv[id-1].id)
    out = @descr.build("odel", [inv[id-1].KtoChto])
    inv.delete_at(id-1)
    out
  end

  def addnpc(sender, message)
    p = @players[sender]
    return @descr['nosens'] if p.sensibleness < @need4players_action
    l = @locations[p.where]
    return @descr['locaccessdenied'] if !locrights?(p, l)
    ObjectCreate(sender, "NPC #{message}")
  end

  def ObjectCreate(sender, message)
    p = @players[sender]
    l = @locations[p.where]
    message =~/^([a-zA-Z0-9]{2,18})\s([\s0-9a-zA-ZёЁА-Яа-я\,]{3,729})$/m
    return @descr['error'] if $1.nil? || $2.nil?
    type = $1.strip
    names = $2.strip
    case type
      when 'NPC'
        an = names.split(',')
        return @descr['error'] if an.size != 6
        an.each { |n| return @descr['namealreadyexits'] if !MyNameUnique?(sender, n, true) }
        o = CreateObject(names, type, "")
        o.id_parent = l.id
        o.id_owner = p.id
        o.parent_type = 'location'
        o.number_of_uses = 0
        @db.updateobject(o)
        l.objects.push(o)
      else
        o = CreateObject(names, type, "")
        o.id_parent = p.id
        o.id_owner = p.id
        o.parent_type = 'player'
        o.number_of_uses = 0
        @db.updateobject(o)
        p.AddItem(o)
    end
    @descr['ok']
  end

  def UseObject(sender, message)
    id = message.to_i
    p = @players[sender]
    l = @locations[p.where]
    inv = p.inventory
    return @descr['youareempty'] if inv.empty?
    return @descr['badnum'] if inv.size < id || id == 0
    item = inv[id-1]
    out = []
    out[0] = ''
    case item.type
      when 'rune'
        item.use
      #return nil
      when 'cardspack'
        return @descr['nosens'] if (p.sensibleness < 1)
        cp = CardsPack.new
        out[0] = cp.Doit(p.sensibleness)

      when 'simple'
        unless item.use
          return @descr['error'] if item.descriptions.nil?
          out = TextBuild(item.descriptions, p)
          showtoall(sender, out[1], p.where)
        end
      else
        return @descr['anotheruse']
    end
    if item.number_of_uses > 0

      item.number_of_uses-=1

      if item.number_of_uses > 0
        item.saveself
      else
        @db.deleteobject(item.id)
        out[0] = out[0] + "\n" + @descr.build("odel", [item.KtoChto])
        p.inventory.delete(item)
        sleep 1
      end
    end
    out[0]
  end

  def SpecifyTo(sender, message)
    p = @players[sender]
    dir = ""
    case message.strip
      when /^((с)|(север))$/i
        dir = 'n'
      when /^((ю)|(юг))$/i
        dir = 's'
      when /^((з)|(запад))$/i
        dir = 'w'
      when /^((в)|(восток))$/i
        dir = 'e'
      when /^((вв)|(верх)|(вверх))$/i
        dir = 'u'
      when /^((вн)|(вниз))$/i
        dir = 'd'
      when /^#{USER_NAME_REGEX}$/i
        sender2 = GetAddrByName(sender, message)
        return @descr['unknownname'] unless sender2
        p2 = @players[sender2]
        return @descr.build("playernothere", [p2.chey]) if p.where != p2.where || !p2.ready
        out = TextBuild(@descr['SpecifyToPlayer'], p, p2)
        showtoall(sender, out[1], p.where, sender2)
        sendmess(sender2, out[2]) unless out[2].nil?
        return out[0]
      else
        return @descr['error']
    end
    out = TextBuild(@descr.build('SpecifyTo', [@descr["to"+dir]]), p)
    showtoall(sender, out[1], p.where)
    return out[0]
  end

  def CallPlayer(sender, message)
    sender2 = GetAddrByName(sender, message)
    return @descr['unknownname'] unless sender2
    p2 = @players[sender2]
    p = @players[sender]
    l = @locations[p.where]
    l2 = @locations[p2.where]
    return @descr['locaccessdenied'] if !locrights?(p, l, l2)
    return @descr['nosens'] if p.sensibleness < @need4players_action
    moveplayers(sender, p2.where, p.where, sender2)
  end

  def Social(soc, sender, me, setposition=false)
    message = (me.nil?) ? me : me.strip
    p = @players[sender]
    l = @locations[p.where]
    rnd = rand(3).to_s
    out = Array.new
    case message
      when nil
        out = TextBuild(@descr[soc+rnd], p) if message.nil? && @descr.present?(soc+rnd)

      when /^(#{USER_NAME_REGEX})$/i
        name = $1
        sender2 = GetAddrByName(sender, name)
        if sender2 != false && @descr.present?(soc+rnd+"toPlayer")
          p2 = @players[sender2]
          return @descr.build("playernothere", [p2.chey]) if p.where != p2.where || !p2.ready
          out = TextBuild(@descr[soc+rnd+"toPlayer"], p, p2)
        else
          sender2 = false
          mess = (p.realise?(@time, l.power_place)) ? message : rndmes(message) unless l.power_place
          mess = message if l.power_place
          out = TextBuild(@descr.build(soc+rnd+"AndSay", [mess]),
                          p) if @descr.present?(soc+rnd+"AndSay")

          return @descr['error'] unless @descr.present?(soc+rnd+"AndSay")
        end
      when /(#{USER_NAME_REGEX}):\s*(.+)/m
        name = $1
        mess = (p.realise?(@time, l.power_place)) ? $2 : rndmes($2)
        sender2 = GetAddrByName(sender, name)
        if sender2 != false && @descr.present?(soc+rnd+"toPlayerAndSay")
          p2 = @players[sender2]
          return @descr.build("playernothere", [p2.chey]) if p.where != p2.where || !p2.ready
          out = TextBuild(@descr.build(soc+rnd+"toPlayerAndSay", [mess]), p, p2)
        else
          sender2 = false
          out = TextBuild(@descr.build(soc+rnd+"AndSay", [(p.realise?(@time, l.power_place)) ? message : rndmes(message)]), p) unless sender2
          return @descr['error'] unless @descr.present?(soc+rnd+"AndSay")

        end
      when /^\*(.+)\*$/i
        return @descr['nosens'] if p.sensibleness < @need4players_action

        out = TextBuild(@descr.build(soc+rnd+"AndSay",
                                     [(p.realise?(@time, l.power_place)) ? $1 : rndmes($1)]), p) if @descr.present?(soc+rnd+"AndSay")
        return @descr['error'] unless @descr.present?(soc+rnd+"AndSay")
      else
        out = TextBuild(@descr.build(soc+rnd+"AndSay",
                                     [(p.realise?(@time, l.power_place)) ? message : rndmes(message)]), p) if @descr.present?(soc+rnd+"AndSay")
        return @descr['error'] unless @descr.present?(soc+rnd+"AndSay")
    end
    return @descr['error'] if sender == false || sender2 == sender || out.size == 0
    return @descr['error'] unless !sender2.nil?||(out.size >= 3 && sender2)||(out.size >= 2 && !sender2)
    return out[3] if p.state == out[2] && setposition

    sendmess(sender2, out[2]) if sender2 && !out[2].nil?
    showtoall(sender, out[1], p.where, sender2)
    p.state = out[2] if setposition
    return out[0]
  end

  def Mail2Player(sender, message)
    p = @players[sender]
    return @descr['nosens'] if p.sensibleness < @need
    l = @locations[p.where]
    return @descr['youneedmailbox'] unless l.name == 'Почта'
    message =~ /(#{USER_NAME_REGEX}):\s*(.*)/m
    name = $1
    mess = $2
#message.sub(/^(#{USER_NAME_REGEX}):\s/,'')
#message.sub(/:((\s)|(.))+/i,'')
    sender2 = GetAddrByName(sender, name)
    return @descr['unknownname'] unless sender2
    p2 = @players[sender2]
    return @descr.build('playerisonline', [p2.name]) if p2.ready
    descrs = TextBuild(@descr.build('Mail2Player', [p2.komu, mess]), p)
    return @descr['error'] if descrs.size < 3
    sendmess(sender2, descrs[2])
    showtoall(sender, descrs[1], p.where)
    return descrs[0]
  end

  def GiveObject2Player(sender, message)
    player = @players[sender]
    #return @descr['nosens'] if player.sensibleness < @need
    id = message.sub(/\s(#{USER_NAME_REGEX})$/i, '').to_i
    name = message.sub(/^[0-9]{1,3}\s/, '')
    sender2 = GetAddrByName(sender, name)
    return @descr['unknownname'] unless sender2
    player2 = @players[sender2]
    return @descr.build("playernothere", [player2.chey]) if player.where != player2.where || !player2.ready
    inv1 = player.inventory
    return @descr['youareempty'] if inv1.empty?
    return @descr['badnum'] if inv1.size < id || id == 0
    obj = inv1[id-1]
    obj.id_parent = player2.id
    @db.updateobject(obj)
    player2.inventory.push(obj)
    inv1.delete_at(id-1)
    descrs = TextBuild(@descr.build('GiveObject2Player', [obj.KogoChto]), player, player2)
    return @descr['givedescrerror'] if descrs.length != 3
    str2me = descrs[0]
    str2player = descrs[1]
    str2all = descrs[2]
    showtoall(sender, str2all, player.where, sender2)
    sendmess(sender2, str2player)
    return str2me
  end

  def TakeObject(sender, message)
    id = message.to_i
    p = @players[sender]
    l = @locations[p.where]
    #return @descr['nosens'] if p.sensibleness < @need
    inv = p.inventory
    objs = l.objects
    return @descr['hereisempty'] if objs.empty?
    return @descr['badnum'] if objs.size < id || id == 0
    item = objs[id-1]
    return @descr['hereisempty'] if item.type == 'NPC' && p.rights != 'admin'
    item.id_parent = p.id
    item.parent_type = 'player'
    @db.updateobject(item)
    inv.push(item)
    objs.delete_at(id-1)
    out = TextBuild(@descr.build("TakeObject", [item.KogoChto]), p)
    showtoall(sender, out[1], p.where)
    out[0]
  end

  def MiscarryObject(sender, message, light=false)
    id = message.to_i
    p = @players[sender]
    l = @locations[p.where]
    #return @descr['nosens'] if p.sensibleness < @need
    inv = p.inventory
    return @descr['youareempty'] if inv.empty?
    return @descr['badnum'] if inv.size < id || id == 0
    obj = inv[id-1]
    obj.id_parent = l.id
    obj.parent_type = 'location'
    @db.updateobject(obj)
    l.objects.push(obj)
    inv.delete_at(id-1)
    socdescr = "MiscarryObject" unless light
    socdescr = "MiscarryObjectLight" if light
    out = TextBuild(@descr.build(socdescr, [obj.KogoChto]), p)
    showtoall(sender, out[1], p.where)
    out[0]
  end

  def SetObjDescrs(sender, message, type="descr")
    p = @players[sender]
    return @descr['nosens'] if p.sensibleness < @need
    inv = p.inventory
    return @descr['youareempty'] if inv.empty?
    id = message.gsub(/\s.+$/, '').to_i
    return @descr['badnum'] if inv.size < id
    desc = message.gsub(/^[0-9]{1,3}\s/, '')
    o = inv[id-1]
    unless p.rights == 'admin'
      return @descr['notyourobj'] unless p.id == o.id_owner
    end
    o.descriptions = desc if type == "actions"
    o.descr = desc if type == "descr"
    o.adjectives = desc if type == "adj"
    o.saveself
    r = o.descriptions + "\n\n" + o.descr + "\n\n" + o.adjectives + "\n\n" + @descr['ok']
    r
  end

  def SetKeyDescr(sender, message)
    p = @players[sender]
    return @descr['nosens'] if p.sensibleness < @need4players_action
    inv = p.inventory
    return @descr['youareempty'] if inv.empty?
    id = message.gsub(/\s.+$/, '').to_i
    return @descr['badnum'] if inv.size < id
    desc = message.gsub(/^[0-9]{1,3}\s/, '')
    o = inv[id-1]
    return @descr['isnotkey'] unless o.type == 'key'
    d = o.data.split(',')
    return @descr['notyourkey'] unless p.id == @locations[d[0].to_i].ownerid
    return @descr['notyourkey'] unless p.id == @locations[d[2].to_i].ownerid
    o.descriptions = desc
    @db.updateobject(o)
    @descr['ok']
  end

  def DirectOpenClose(sender, direct, open)
    p = @players[sender]
    return @descr['nosens'] if p.sensibleness < @need
    l1 = @locations[p.where]
    dir1 = p.where
    dir2 = l1[direct]
    return @descr['baddirect4'+((open) ? 'open' : 'close')] if dir2 == 0 || dir2 == nil
    return @descr['alreadyclose'] if dir2 < 0 && !open
    return @descr['alreadyopen'] if dir2 > 0 && open
    dir2 = dir2 * -1 if dir2 < 0
    l2 = @locations[dir2]
    return @descr['youareempty4'+((open) ? 'open' : 'close')] if p.inventory.empty?
    keyfound = false
    itemdescr = []
    p.inventory.each do |item|
      if item.type == 'key'
        d = item.data.split(',')
        if ((d[0].to_i == dir1 && d[1] == direct)||
            (d[2].to_i == dir1 && d[3] == direct))
          dir1 = dir1*-1 if !open
          dir2 = dir2*-1 if !open
          itemdescr = TextBuild(item.descriptions, p) unless item.descriptions.nil?
          keyfound = true
          break
        end
      end
    end
    return @descr['youareempty4'+((open) ? 'open' : 'close')] if !keyfound
    l1[direct] = dir2
    case direct
      when "n"
        l2.s = dir1
        reversedirect = 's'
      when "s"
        l2.n = dir1
        reversedirect = 'n'
      when "w"
        l2.e = dir1
        reversedirect = 'e'
      when "e"
        l2.w = dir1
        reversedirect = 'w'
      when "u"
        l2.d = dir1
        reversedirect = 'd'
      when "d"
        l2.u = dir1
        reversedirect = 'u'
    end
    @db.updatelocation(l1)
    @db.updatelocation(l2)
    descrs = []
    if itemdescr.nil? || itemdescr.size < 6
      descrs = TextBuild(@descr.build((open) ? 'openthedoor' : 'closethedoor', [@descr["gde"+direct], @descr["gde"+reversedirect]]), p)
    else
      if open
        descrs[0] = itemdescr[0].gsub('~gde~', @descr["gde"+direct])
        descrs[1] = itemdescr[1].gsub('~gde~', @descr["gde"+direct])
        descrs[2] = itemdescr[2].gsub('~gde~', @descr["gde"+reversedirect])
      else
        descrs[0] = itemdescr[3].gsub('~gde~', @descr["gde"+direct])
        descrs[1] = itemdescr[4].gsub('~gde~', @descr["gde"+direct])
        descrs[2] = itemdescr[5].gsub('~gde~', @descr["gde"+reversedirect])
      end
    end
    showtoall(sender, descrs[2], l2.id)
    showtoall(sender, descrs[1], p.where)
    return descrs[0]
  end

  def Inventory(sender)
    p = @players[sender]
    inv = p.inventory
    return @descr['youareempty'] if inv.empty?
    out = @descr['invheader']
    inv.each_with_index do |item, i|
      out += "\n#{i+1}. #{item.KtoChto}"
    end
    out
  end

  def CreateKey(sender, message)
    message =~ /^([nsweud])\s(.+)/m
    direct = $1
    names = $2
    p = @players[sender]
    l = @locations[p.where]
    dir1 = p.where
    dir2 = l[direct]
    d1 = direct
    return @descr['baddirect'] if dir2 == 0 || dir2.nil?
    return @descr['nosens'] if p.sensibleness < @need4players_action
    case direct
      when "n"
        d2 = 's'
      when "s"
        d2 = 'n'
      when "w"
        d2 = 'e'
      when "e"
        d2 = 'w'
      when "u"
        d2 = 'd'
      when "d"
        d2 = 'u'
    end
    l2 = @locations[dir2]
    return @descr['locaccessdenied'] if !locrights?(p, l, l2)

    key = CreateObject(names, 'key', [dir1, d1, dir2, d2] * ",")
    key.id_parent = p.id
    key.id_owner = p.id
    key.parent_type = 'player'
    @db.updateobject(key)
    p.AddItem(key)
    @descr['ok']
  end

  def CreateObject(names, type, data)
    case type
      when 'NPC'
        obj = NPC.new(names, type)
      when 'rune'
        obj = Rune.new(names, type)
      else
        obj = Obj.new(names, type)
    end
    obj.data = data
    obj.id = @db.addobject(obj)
    return obj
  end

  def SetMyDescr(sender, message)
    player = @players[sender]
    return @descr['nosens'] if player.sensibleness < @need
    return player.descr if message.nil?
    player.descr = message
    @db.updateplayer(sender, player)
    @descr['ok']
  end

  def isNumeric(s)
    Float(s) != nil rescue false
  end

  def LookTo(sender, message)
    player = @players[sender]
    if isNumeric(message)
      inv = player.inventory
      id = message.to_i
      o = inv[id-1]
      return @descr['badnum'] if inv.size < id || id == 0 || o.nil?
      return @descr.build('notdescr', o.KtoChto) if o.descr.nil? ||
          o.descr == ""
      return o.descr
    end
    sender2 = GetAddrByName(sender, message)
    loc = @locations[player.where]
    unless sender2
      name = message.downcase
      idx = loc.objects.index { |o|
        o.type == 'NPC' &&
            (o.KtoChto.downcase == name ||
                o.KogoChego.downcase == name ||
                o.KomuChemu.downcase == name ||
                o.KogoChto.downcase == name ||
                o.KemChem.downcase == name ||
                o.OKomOChom.downcase == name)
      }
      if idx != nil
        player2 = loc.objects[idx]
      else
        return @descr['unknownname']
      end
    else
      player2 = @players[sender2]
    end
    return @descr.build("playernothere", [player2.chey]) if player.where != player2.where || !player2.ready
    text = @descr.build('LookTo', [player2.descr])
    texts = TextBuild(text, player, player2)
    showtoall(sender, texts[0], player.where, sender2)
    if (player2.class == Obj || player2.class == NPC)
      player2.listen(sender, message)
    else
      sendmess(sender2, texts[1])
    end
    texts[2]
  end

  def Shout(sender, message)
    player = @players[sender]
    return @descr['nosens'] if player.sensibleness < @need
    loc = @locations[player.where]
    text = @descr.build('shout', [message])
    texts = TextBuild(text, player)
    showtoall(sender, texts[0], player.where)
    showtoall(sender, texts[1], loc.n) unless loc.n == 0
    showtoall(sender, texts[1], loc.s) unless loc.s == 0
    showtoall(sender, texts[1], loc.w) unless loc.w == 0
    showtoall(sender, texts[1], loc.e) unless loc.e == 0
    showtoall(sender, texts[1], loc.u) unless loc.u == 0
    showtoall(sender, texts[1], loc.d) unless loc.d == 0
    texts[2]
  end

  def MyNameUnique?(sender, n, fullcheck=false)
    name = n.downcase
    @players.each { |addr, player|
      if fullcheck
        return false if (player.name.downcase == name ||
            player.kogo.downcase == name ||
            player.komu.downcase == name ||
            player.kem.downcase == name ||
            player.okom.downcase == name ||
            player.chey.downcase == name)
      else
        return false if (sender != addr) &&
            (player.name.downcase == name ||
                player.kogo.downcase == name ||
                player.komu.downcase == name ||
                player.kem.downcase == name ||
                player.okom.downcase == name ||
                player.chey.downcase == name)
      end
    }
    return true
  end

  def GetAddrByName(sender, n)
    name = n.downcase
    @players.each { |addr, player|
      return addr if (sender != addr) &&
          (player.name.downcase == name ||
              player.kogo.downcase == name ||
              player.komu.downcase == name ||
              player.kem.downcase == name ||
              player.okom.downcase == name ||
              player.chey.downcase == name) }
    return false
  end

  def redirect(sender, cmd)
    direct = cmd.sub(/[0-9]{1,4}/i, '').strip
    id = cmd.sub(/[nsweud]/i, '').strip.to_i
    p = @players[sender]
    return @descr['nosens'] if p.sensibleness < @need
    l1 = @locations[p.where]
    if id > 0
      return @descr['unknowlocation'] if (@locations[id].nil?)
      l2 = @locations[id]
      return @descr['locaccessdenied'] if !locrights?(p, l1, l2)
    end
    return @descr['locaccessdenied'] if !locrights?(p, l1)
    l1[direct] = id
    savelocation(sender)
  end

  def TextBuild(str, player, player2=false)
    txt = str
    if player2 != false
      txt = txt.gsub('~~kto~~', player2.name)
      txt = txt.gsub('~~kogo~~', player2.kogo)
      txt = txt.gsub('~~komu~~', player2.komu)
      txt = txt.gsub('~~kem~~', player2.kem)
      txt = txt.gsub('~~okom~~', player2.okom)
      txt = txt.gsub('~~chey~~', player2.chey)
      txt = txt.gsub(/(\[\[[^\[\]]+\]\])|(\{\{)|(\}\})/, '') if player2.male?
      txt = txt.gsub(/(\{\{[^\{\}]+\}\})|(\[\[)|(\]\])/, '') if player2.female?
    end
    txt = txt.gsub('~kto~', player.name)
    txt = txt.gsub('~kogo~', player.kogo)
    txt = txt.gsub('~komu~', player.komu)
    txt = txt.gsub('~kem~', player.kem)
    txt = txt.gsub('~okom~', player.okom)
    txt = txt.gsub('~chey~', player.chey)
    txt = txt.gsub(/(\[[^\[\]]+\])|(\{)|(\})/, '') if player.male?
    txt = txt.gsub(/(\{[^\{\}]+\})|(\[)|(\])/, '') if player.female?
    out = txt.split(')><(')
    return "" if out[0].nil? && out[1].nil? && out[2].nil?
    return (out.size >= 2) ? out : txt
  end

  def SaveGame()
    @players.each { |addr, player| @db.updateplayer(addr, player) }
    @descr['ok']
  end

  def recall(sender, id, force=false)
    p = @players[sender]
    return @descr['nosens'] if p.sensibleness < @need4players_action and !force
    l1 = @locations[p.where]
    return @descr['unknowlocation'] if (@locations[id].nil?)
    l2 = @locations[id]
    return @descr['locaccessdenied'] if !locrights?(p, l1, l2) and !force
    moveplayers(sender, @players[sender].where, id, sender)
  end

  def Last()
    list = @db.last(20)
    txt = ""
    list.each { |p|
      txt += "\n"
      txt += p[0]
      txt += "\t\t\t\t\t"
      txt += Time.at(p[1]).to_s
    }
    txt
  end

  def dbshow(sql)
#		s = "db:\n"
#		@db.q("select * from knownlocations;").each{|p,l|

#	    s+=(p.to_s+" "+ l.to_s+"\n")
#	}
#	@db.q("select * from chars;").to_s+"\n"+
#	@db.q("select * from descriptions;").to_s
    @db.q(sql)
#		s = result[0].columns
  end

  def send(&block)
    @sys_send = block
  end

  def check(sender)
    if @players.key?(sender) && @players[sender].ready
      @players[sender].lat = @time
      @players[sender].lrealise = @time if @players[sender].lrealise < 0
      true
    else
      if !@players.key?(sender)
        @players[sender] = Player.new(sender, 'noname',
                                      'noname', 'noname', 'noname',
                                      'noname', 'nosex', false, START_LOCATION)
        @players[sender].createdate = Time.now.to_i
        id = @db.addplayer(sender, @players[sender])
        @players[sender].id = id
        @players[sender].addr = sender
      end

      @players[sender].lat = @time
      @players[sender].lrealise = @time if @players[sender].lrealise < 0
      false
    end
  end

  def go(sender, direction)
    if sender.class == NPC
      p = sender
    else
      p = @players[sender]
    end
    l = @locations[p.where]
    if l.nil?
      p.where = 1
      l = @locations[p.where]
    end
    rnd = rand(4)
    descrs = TextBuild(@descr.build("GoTo"+rnd.to_s,
                                    [@descr["to"+direction], @descr["fromreverse"+direction]]), p)
    destloc = l[direction]
    if destloc > 0
      #Thread.new(p.followingplayers,p.where) do |pfps,pw|
      #pfps.each do |addr|
      #fp = @players[addr]
      #next if fp.where != pw || !fp.ready
      #sendmess(addr, go(addr,direction))
      #end
      #end

      outdescr = l.outdescr(direction, p)

      txt = (outdescr.nil?) ? descrs[1] : outdescr[1]
      showtoall(sender, txt, p.where)
      oldloc = p.where

      p.where = destloc if p.realise?(@time, l.power_place)
      p.where = rndloc unless p.realise?(@time, l.power_place)
      if sender.class == NPC
        @locations[oldloc].objects.delete_if { |x|
          x.id == sender.id }
        @locations[destloc].objects.push sender
        sender.saveself
      end
      l = @locations[p.where]

      indescr = l.indescr(direction, p)

      txt = (indescr.nil?) ? descrs[2] : indescr[1]
      showtoall(sender, txt, p.where)

      rstr = (outdescr.nil?) ? descrs[0] : outdescr[0]
      if indescr.nil?
        rstr += look(sender) unless p.class == NPC
      else
        rstr += "\n"+indescr[0]+look(sender) unless p.class == NPC
      end

      l.objects.each do |o|
        Thread.new {
          begin
            o.incomingplayer(sender, p)
          rescue
            errmess = "\n# # #\nERROR: #{$!.to_s}\n\nin embeded obect incoming player event code \""+
                o.KtoChto()+"\" in location \##{o.id_parent.to_s}\n# # #"
            sendmess($MAINADDR, errmess)
          end
        }
      end
    else
      outdescr = l.outdescr(direction, p)
      if !outdescr.nil? && l[direction] > -1
        showtoall(sender, outdescr[1], p.where)
        rstr = outdescr[0] #+"\n\r"+descrs[3]
      else
        rstr = descrs[3]
      end
    end

    p.state = "" # @descr['DefaultPlayerPosition']
    @db.updateplayer(sender, p) unless p.class == NPC
    return rstr unless p.class == NPC
  end

  def ObjsInLoc(where)
    objs = @locations[where].objects
    out = @descr['ObjsInLocHeader']
    return "" if objs.empty?
    n = 0
    objs.each_with_index do |obj, i|
      if obj.type != 'NPC'
        if obj.adjectives.nil? || obj.adjectives == ""
          out += "\n#{i+1}. #{obj.KtoChto}"
        else
          out += "\n#{i+1}. #{obj.adjectives}"
        end
      else
        n+=1
      end
    end
    return "" if objs.size == n
    out
  end

  def look(sender)
    p = @players[sender]
    where = p.where
    l = @locations[where]
    #	showtoall(sender, "\n#{@players[sender].name} locking around", @players[sender].where)
    ret = "\n «<з>#{l.name}</з>»\n#{l.descr}" + whoishere(sender, where)
    ret += ObjsInLoc(where)
    ret += "\n" + @descr['noexits'] if l.noexits?
    ret += "\n"+self.exits(where) unless l.noexits?
    @db.addknownloc(p) if p.FirstTimeHere?
    return ret
  end

#    private
  def showtoall(sender, descr, location=0, sender2=false)
    if location != 0
      @players.each { |addr, char|
        if sender2
          sendmess(addr, descr) if addr != sender2 && addr != sender && char.ready && char.where == location
        else
          sendmess(addr, descr) if addr != sender && char.ready && char.where == location
        end
      }
    else
      @players.each { |addr, char|
        sendmess(addr, descr) if addr != sender && char.ready
      }
    end

#	  Thread.new(sender, descr, location, sender2, @players) do |s,d,l,s2,ps|
#		if l != 0
#		    ps.each{ | addr, char |
#			if s2
#				sendmess(addr, d) if addr != s2 && addr != s && char.ready && char.where == l
#			else
#				sendmess(addr, d) if addr != s && char.ready && char.where == l
#			end
#		    }
#		else
#		    ps.each{ | addr, char |
#				sendmess(addr, d) if addr != s && char.ready
#		    }
#		end
#	  end


  end

  def whoishere(sender, location)
    chars = @descr['here']
    l = @locations[location]
    @players.each { |addr, char|
      if addr != sender && char.ready && char.where == location
        chars += "\n"+char.name
        chars += " (#{char.state})" unless char.state.strip.empty?
        unless l.powerplace?
          descrsrealise = TextBuild(@descr['descrsrealise'], char)
          chars += descrsrealise[1] if char.realise?(@time, l.power_place)
          chars += descrsrealise[0] unless char.realise?(@time, l.power_place)
        end
      end
    }
    objs = @locations[@players[sender].where].objects
    objs.each { |o|
      if o.type =='NPC'
        if o.adjectives.nil? || o.adjectives == ""
          chars += "\n"+o.KtoChto
        else
          chars += "\n"+o.adjectives
        end
      end
    }
    if chars.length > @descr['here'].length
      return chars
    else
      return ""
    end
  end

  def who(sender)
    p = @players[sender]
# 		return @descr['nosens'] if p.sensibleness < @need4who
    chars = @descr['whoheader']
    @players.each { |addr, char|
      if char.ready
        chars += "\n <з>#{char.name}</з> - #{@descr[char.sex]} - "
        chars += (p.KnownLoc?(char.where)) ? "#{@locations[char.where].name}" : @descr['unknownlocation']
        chars += " ( #{char.where.to_s} )" if p.rights == 'admin' || p.id == @locations[char.where].ownerid
      end
    }
    chars
  end

  def locrights?(p, l1, l2=nil)
    return true if p.rights == 'admin'
    if l2.nil?
      return true if p.id == l1.ownerid
    else
      return true if p.id == l1.ownerid && p.id == l2.ownerid
    end
    return false
  end

  def locedit(sender, str)
    p = @players[sender]
    l = @locations[p.where]
    return @descr['locaccessdenied'] if !locrights?(p, l)
    return @descr['nosens'] if p.sensibleness < @need
    case str
      when /^descr\s.+$/
        l.descr = str.sub(/descr\s/, '')

      when /^name\s.+$/
        l.name = str.sub(/name\s/, '')

      when /^nid\s.+$/
        l.nid = str.sub(/nid\s/, '')

      when /^nid$/
        return l.nid

      when /^sid\s.+$/
        l.sid = str.sub(/sid\s/, '')
      when /^sid$/
        return l.sid

      when /^wid\s.+$/
        l.wid = str.sub(/wid\s/, '')
      when /^wid$/
        return l.wid

      when /^eid\s.+$/
        l.eid = str.sub(/eid\s/, '')
      when /^eid$/
        return l.eid

      when /^uid\s.+$/
        l.uid = str.sub(/uid\s/, '')
      when /^uid$/
        return l.uid

      when /^did\s.+$/
        l.did = str.sub(/did\s/, '')
      when /^did$/
        return l.did

      when /^nod\s.+$/
        l.nod = str.sub(/nod\s/, '')
      when /^nod$/
        return l.nod

      when /^sod\s.+$/
        l.sod = str.sub(/sod\s/, '')
      when /^sod$/
        return l.sod

      when /^wod\s.+$/
        l.wod = str.sub(/wod\s/, '')
      when /^wod$/
        return l.wod

      when /^eod\s.+$/
        l.eod = str.sub(/eod\s/, '')
      when /^eod$/
        return l.eod

      when /^uod\s.+$/
        l.uod = str.sub(/uod\s/, '')
      when /^uod$/
        return l.uod

      when /^dod\s.+$/
        l.dod = str.sub(/dod\s/, '')
      when /^dod$/
        return l.dod

      when /^are enable$/
        l.areflag = true
      when /^are disable$/
        l.areflag = false

      when /^PP enable$/
        return @descr['locaccessdenied'] unless p.rights == 'admin'
        l.power_place = true
      when /^PP disable$/
        return @descr['locaccessdenied'] unless p.rights == 'admin'
        l.power_place = false

      else
        return "\nsyntax error"
    end
    savelocation(sender)
    look(sender)
  end

  def savelocation(player)
    @db.updatelocation(@locations[@players[player].where])
    @descr["ok"]
  end

  def newlocation(sender, message)
    p = @players[sender]
    curloc = p.where
    l = @locations[curloc]
    return @descr['locaccessdenied'] if !locrights?(p, l)
    return @descr['nosens'] if p.sensibleness < @need4newloc
    if message =~/^([nsweud])\s?(.+)?$/i
      direct = $1
      name = $2
    else
      direct = message
    end
    if l[direct] == 0
      l = Location.new()
      case direct.downcase
        when "n"
          l.s = curloc
        when "s"
          l.n = curloc
        when "w"
          l.e = curloc
        when "e"
          l.w = curloc
        when "u"
          l.d = curloc
        when "d"
          l.u = curloc
      end
      l.ownerid = p.id
      l.name = name if message != direct
      n = @db.addlocation(l)
      @locations[curloc][direct] = n
      l.id = n
      @locations[n] = l
      savelocation(sender)
      descrs = TextBuild(@descr.build('newlocation', [@descr["to"+direct]]), p)
      showtoall(sender, descrs[1], curloc)
      return descrs[0]
    else
      @descr['cantcreate']
    end
  end

  def insertlocation(sender, direct)
    p = @players[sender]
    curloc = p.where
    l = @locations[curloc]
    return @descr['locaccessdenied'] if !locrights?(p, l)
    return @descr['nosens'] if p.sensibleness < @need4newloc
    if l[direct] > 0
      n1 = l[direct]
      l1 = @locations[n1.abs]
      dir1 = ""
      l0 = l
      l = Location.new()
      case direct
        when "n"
          l.s = curloc
          dir1 = "s"
        when "s"
          l.n = curloc
          dir1 = "n"
        when "w"
          l.e = curloc
          dir1 = "e"
        when "e"
          l.w = curloc
          dir1 = "w"
        when "u"
          l.d = curloc
          dir1 = "d"
        when "d"
          l.u = curloc
          dir1 = "u"
      end
      l.ownerid = p.id
      l[direct] = n1
      l.name = l0.name
      l.descr = l0.descr
      n = @db.addlocation(l)
      @locations[curloc][direct] = n
      l.id = n
      @locations[n] = l
      l1[dir1] = n
      @db.updatelocation(l1)
      savelocation(sender)
      descrs = TextBuild(@descr.build('insertlocation', [@descr["to"+direct]]), p)
      showtoall(sender, descrs[1], curloc)
      return descrs[0]
    else
      @descr['cantinsert']
    end
  end

  def dellocation(sender, direct)
    curloc = @players[sender].where
    destloc = @locations[curloc][direct].abs
    p = @players[sender]
    l1 = @locations[curloc]
    l2 = @locations[destloc]
    return @descr['baddirect'] if destloc == 0
    if l2.numexits? < 2
      return @descr['locaccessdenied'] if !locrights?(p, l1, l2)
      return @descr['nosens'] if p.sensibleness < @need4delloc
      descrs = TextBuild(@descr.build('dellocation', [@descr["to"+direct]]), p)
      showtoall(sender, descrs[2], destloc)
      moveplayers(sender, destloc)
      @db.deletelocation(destloc)
      @locations[destloc] = nil
      #	    @locations.delete_at(destloc)
      @locations[curloc][direct] = 0
      savelocation(sender)
      showtoall(sender, descrs[1], curloc)
      descrs[0]
    else
      @descr['cantdel']
    end
  end

  def dellocationbyid(sender, id)
#	    return 'временно отключено'
    return "bad id!" if @locations[id].nil?
    if @locations[id].numexits? <= 1 && @players[sender].where != id
      showtoall(sender, @descr['locationwillbedeleted'], id)
      moveplayers(sender, id)
      @db.deletelocation(id)
      #	    @locations.delete_at(id)
      @locations[id] = nil
      @descr['ok']
    else
      @descr['cantdel']
    end
  end

  def lxml4client(sender)
    if sender.class == Location
      l = sender
      cur = l.id
    else
      p = @players[sender]
      cur = @players[sender].where
      l = @locations[cur]
      return @descr['locaccessdenied'] if !locrights?(p, l)
    end
    xml =""
    xml = "l#{cur.to_s}.xml\n" unless sender.class == Location
    xml += '<?xml version="1.0" encoding="UTF-8"?>'+"\n"
    xml += "<!DOCTYPE location SYSTEM \"location.dtd\">\n"
    xml += "<location>\n"

    xml += "	<name sound='#{cur.to_s}_name.wav'>#{l.name}</name>\n"
    xml += "	<descr sound='#{cur.to_s}_descr.wav'>#{l.descr}</descr>\n"

    #xml += "	<nid sound='#{cur.to_s}_nid.wav'>#{l.nid.sub(/\)><\(.+/,'')}</nid>\n" unless l.nid.empty?
    #xml += "	<sid sound='#{cur.to_s}_sid.wav'>#{l.sid.sub(/\)><\(.+/,'')}</sid>\n" unless l.sid.empty?
    #xml += "	<wid sound='#{cur.to_s}_wid.wav'>#{l.wid.sub(/\)><\(.+/,'')}</wid>\n" unless l.wid.empty?
    #xml += "	<eid sound='#{cur.to_s}_eid.wav'>#{l.eid.sub(/\)><\(.+/,'')}</eid>\n" unless l.eid.empty?
    #xml += "	<uid sound='#{cur.to_s}_uid.wav'>#{l.uid.sub(/\)><\(.+/,'')}</uid>\n" unless l.uid.empty?
    #xml += "	<did sound='#{cur.to_s}_did.wav'>#{l.did.sub(/\)><\(.+/,'')}</did>\n" unless l.did.empty?

    if l.n > 0
      nod = l.nod.sub(/\)><\(.+/, '')
      l2 = @locations[l.n]
      nod += l2.sid.sub(/\)><\(.+/, '')
      if l.nod.empty?
        odf = 'goton'
      else
        odf = cur.to_s+'_nod'
      end
      xml += "	<nod sound='#{odf}.wav'>#{nod}</nod>\n"
    end
    if l.s > 0
      sod = l.sod.sub(/\)><\(.+/, '')
      l2 = @locations[l.s]
      sod += l2.nid.sub(/\)><\(.+/, '')
      if l.sod.empty?
        odf = 'gotos'
      else
        odf = cur.to_s+'_sod'
      end
      xml += "	<sod sound='#{odf}.wav'>#{sod}</sod>\n"
    end
    if l.w > 0
      wod = l.wod.sub(/\)><\(.+/, '')
      l2 = @locations[l.w]
      wod += l2.eid.sub(/\)><\(.+/, '')
      if l.wod.empty?
        odf = 'gotow'
      else
        odf = cur.to_s+'_wod'
      end
      xml += "	<wod sound='#{odf}.wav'>#{wod}</wod>\n"
    end
    if l.e > 0
      eod = l.eod.sub(/\)><\(.+/, '')
      l2 = @locations[l.e]
      eod += l2.wid.sub(/\)><\(.+/, '')
      if l.eod.empty?
        odf = 'gotoe'
      else
        odf = cur.to_s+'_eod'
      end
      xml += "	<eod sound='#{odf}.wav'>#{eod}</eod>\n"
    end

    if l.u > 0
      uod = l.uod.sub(/\)><\(.+/, '')
      l2 = @locations[l.u]
      uod += l2.did.sub(/\)><\(.+/, '')
      if l.uod.empty?
        odf = 'gotou'
      else
        odf = cur.to_s+'_uod'
      end
      xml += "	<uod sound='#{odf}.wav'>#{uod}</uod>\n"
    end
    if l.d > 0
      dod = l.dod.sub(/\)><\(.+/, '')
      l2 = @locations[l.d]
      dod += l2.uid.sub(/\)><\(.+/, '')
      if l.dod.empty?
        odf = 'gotod'
      else
        odf = cur.to_s+'_dod'
      end
      xml += "	<dod sound='#{odf}.wav'>#{dod}</dod>\n"
    end

    xml += "	<bgmusic filename='l#{cur.to_s}.mp3' />\n"

    xml += "	<n sound='#{l.n.to_s}_name.wav'>l#{l.n.to_s}.xml</n>\n" if l.n > 0
    xml += "	<s sound='#{l.s.to_s}_name.wav'>l#{l.s.to_s}.xml</s>\n" if l.s > 0
    xml += "	<w sound='#{l.w.to_s}_name.wav'>l#{l.w.to_s}.xml</w>\n" if l.w > 0
    xml += "	<e sound='#{l.e.to_s}_name.wav'>l#{l.e.to_s}.xml</e>\n" if l.e > 0
    xml += "	<u sound='#{l.u.to_s}_name.wav'>l#{l.u.to_s}.xml</u>\n" if l.u > 0
    xml += "	<d sound='#{l.d.to_s}_name.wav'>l#{l.d.to_s}.xml</d>\n" if l.d > 0
    xml += "</location>\n"
    return xml
  end

  def psavexml(sender, name)
    sender2 = GetAddrByName('none', name)
    return @descr['unknownname'] unless sender2
    system 'mkdir', '-p', name
    #Dir.mkdir(name)
    p = @players[sender2]
    aaa=""
    @locations.each { |l|
      unless l.nil?
        next unless l.ownerid == p.id
        aaa += l.name + "\n"
        xml = lxml4client(l)
        File.open(name+'/'+'l'+l.id.to_s+'.xml', 'w') { |file| file.write xml }
      end
    }
    archname = name+'.zip'
    system 'zip', '-q', '-9', '-r', archname, name
    system 'rm', '-rf', name
    p0 = @players[sender]
    send_email(p0.realemail, p0.komu, "XML "+p.chey, @descr['psavexmlmail'], './'+archname) unless p0.realemail.nil?
    return aaa+"\n"+@descr["xmlsaveok"] if p0.realemail.nil?
    #system 'rm','-f', archname
    return aaa+"\n"+@descr["xmlsendok"]
  end

  def moveplayers(sender, fromloc, destloc=-1, player="all")
    if destloc == -1
      p = @players[sender]
      destloc = p.where
    end
    if player == "all"
      @players.each { |addr, char|
        if char.where == fromloc && char.ready
          out = TextBuild(@descr['MovePlayer'], char)
          showtoall(addr, out[1], fromloc)
          @players[addr].where = destloc
          sendmess(addr, out[0]+look(addr))
          showtoall(addr, out[2], destloc)
          @db.updateplayer(addr, char)
        end
        if !char.ready && char.where == fromloc
          @players[addr].where = destloc
          @db.updateplayer(addr, char)
        end
      }
    else
      return @descr['unknownplayer'] if (@players[player].nil?)
      return @descr['unknowlocation'] if (@locations[destloc].nil?)
      char = @players[player]
      if char.where == fromloc && char.ready
        out = TextBuild(@descr['MovePlayer'], char)
        showtoall(player, out[1], fromloc)
        @players[player].where = destloc
        sendmess(player, out[0]+look(player))
        showtoall(player, out[2], destloc)
        @db.updateplayer(player, char)
        l = @locations[char.where]
        l.objects.each do |o|
          Thread.new {
            begin
              o.incomingplayer(player, char)
            rescue
              errmess = "\n# # #\nERROR: #{$!.to_s}\n\nin embeded obect incoming player event code \""+
                  o.KtoChto()+"\" in location \##{o.id_parent.to_s}\n# # #"
              sendmess($MAINADDR, errmess)
            end
          }
        end

      end
      unless char.ready
        @players[player].where = destloc
        @db.updateplayer(player, char)
      end
    end
    nil
  end

  def start(sender)
    p = @players[sender]
    return @descr['cmdhelpcharcreate'] if (p.name == sender ||
        p.kogo == "noname" ||
        p.komu == "noname" ||
        p.kem == "noname" ||
        p.okom == "noname" ||
        p.chey == "noname" ||
        p.sex == "nosex" ||
        (p.sex != "male" &&
            p.sex != "female"))
    p.ready = true
    p.lastlogin = Time.now.to_i
    d = TextBuild(@descr["entering"], p)
    showtoall(sender, d[2])
    showtoall(sender, d[1], p.where)
    @db.updateplayer(sender, p)
    checksms = ""
    unless p.inventory.index { |o| o.type=='mobile' } == nil
      checksms = @descr.build('smsnum', [p.sms.size.to_s])
    end
    curloc = p.where
    l = @locations[curloc]
    l.objects.each do |o|
      Thread.new {
        begin
          o.incomingplayer(sender, p)
        rescue
          errmess = "\n# # #\nERROR: #{$!.to_s}\n\nin embeded obect incoming player event code \""+
              o.KtoChto()+"\" in location \##{o.id_parent.to_s}\n# # #"
          sendmess($MAINADDR, errmess)
        end
      }
    end

    return d[0]+look(sender)+"\n\n"+checksms
  end

  def stop(sender)
    p = @players[sender]
    return nil unless p.ready
    p.ready = false
    #ProhibitFollowing(sender,'')
    #StopFollow(sender)
    @db.updateplayer(sender, p)
    d = TextBuild(@descr["wakeup"], p)
    showtoall(sender, d[2], p.where)
    showtoall(sender, d[1])
    d[0]
  end

  def exits(loc)
    l = @locations[loc]
    ex = @descr['exits']
    ex += "\n #{@descr['gden']} - #{@locations[l.n].name.downcase}" if l.n > 0
    ex += "\n #{@descr['gden']} - #{@descr['closed']}" if l.n < 0
    ex += "\n #{@descr['gdes']} - #{@locations[l.s].name.downcase}" if l.s > 0
    ex += "\n #{@descr['gdes']} - #{@descr['closed']}" if l.s < 0
    ex += "\n #{@descr['gdew']} - #{@locations[l.w].name.downcase}" if l.w > 0
    ex += "\n #{@descr['gdew']} - #{@descr['closed']}" if l.w < 0
    ex += "\n #{@descr['gdee']} - #{@locations[l.e].name.downcase}" if l.e > 0
    ex += "\n #{@descr['gdee']} - #{@descr['closed']}" if l.e < 0
    ex += "\n #{@descr['gdeu']} - #{@locations[l.u].name.downcase}" if l.u > 0
    ex += "\n #{@descr['gdeu']} - #{@descr['closed']}" if l.u < 0
    ex += "\n #{@descr['gded']} - #{@locations[l.d].name.downcase}" if l.d > 0
    ex += "\n #{@descr['gded']} - #{@descr['closed']}" if l.d < 0
    ex
  end

  def status
    i = 0
    @players.each { |addr, char|
      i = i+1 if char.ready
    }
    @descr.build('statusmessage', [i.to_s, @db.lcount])
  end

  def invite(sender, message)
    addr = message
    if message =~ /^[0-9]{5,14}$/
      addr = message + "@icq.dreamhackers.org"
    end
    #return @descr['alreadyinvited'] if @players.key?(addr)
    invitestr = @descr.build('invite', [players[sender].name])
    if players[sender].sex == 'male'
      invitestr = invitestr.gsub(/<<[^<>]+>>/, '')
    else
      invitestr = invitestr.gsub('<<', '')
      invitestr = invitestr.gsub('>>', '')
    end
    sendmess(addr, invitestr)
    @descr['invitedok']
  end

  def rndmes(message)
    m = message.split
    return m.sort_by { rand } * ' '
  end

  def say(sender, message)
    if sender.class == NPC
      p = sender
    else
      p = @players[sender]
    end
    l = @locations[p.where]
    l.objects.each do |o|
      next if p.class == NPC && p.id == o.id
      o.listen(sender, message)
      sleep 0.1
      return nil if o.silence_flag
    end
    rnd = rand(4).to_s
    unless p.realise?(@time, l.power_place)
      message = rndmes(message)
    end

    case message
      when /^(#{USER_NAME_REGEX}):\s?(.+\?)$/m
        name = $1
        mess = $2
        sender2 = GetAddrByName(sender, name)
        if sender2
          p2 = @players[sender2]
          return @descr.build("playernothere", [p2.chey]) if p.where != p2.where || !p2.ready
          out = TextBuild(@descr.build("Ask"+rnd+"toPlayer", [mess]), p, p2)
          sendmess(sender2, out[2])
        else
          out = TextBuild(@descr.build("Say"+rnd, [message]), p)
        end
      when /^(#{USER_NAME_REGEX}):\s?(.+)/m
        name = $1
        mess = $2
        sender2 = GetAddrByName(sender, name)
        if sender2
          p2 = @players[sender2]
          return @descr.build("playernothere", [p2.chey]) if p.where != p2.where || !p2.ready
          out = TextBuild(@descr.build("Say"+rnd+"toPlayer", [mess]), p, p2)
          sendmess(sender2, out[2])
        else
          out = TextBuild(@descr.build("Say"+rnd, [message]), p)
        end
      when /[.\s]+/m
        if (message[-1]=='?')
          out = TextBuild(@descr.build("Ask"+rnd, [message]), p)
        else
          out = TextBuild(@descr.build("Say"+rnd, [message]), p)
        end
      else
        out = TextBuild(@descr.build("Say"+rnd, [message]), p)
    end

    return @descr['error'] if out.size < 2
    showtoall(sender, out[1], p.where, ((sender2) ? sender2 : false))
#		return nil if sender =~ /^[0-9]{5,14}@icq\.magicfreedom\.com$/
    out[0]
#	nil
  end

  def CharacterRename(sender, message)
    oldPlayer = @players[sender].clone if check(sender)

    if CharCreate(sender, message.split(/\,\s?/)) == @descr['namealreadyexits']
      return @descr['namealreadyexits']
    end

    if check(sender)
      newPlayer = @players[sender]
      texts = TextBuild(@descr['CharRename'], oldPlayer, newPlayer)
      showtoall(sender, texts[1])
      return texts[0]
    else
      return @descr['gogogo']
    end
  end

  def CharCreate(sender, char)
    if (MyNameUnique?(sender, char[0].strip) &&
        MyNameUnique?(sender, char[1].strip) &&
        MyNameUnique?(sender, char[2].strip) &&
        MyNameUnique?(sender, char[3].strip) &&
        MyNameUnique?(sender, char[4].strip) &&
        MyNameUnique?(sender, char[5].strip))

      @players[sender].name = char[0].strip
      @players[sender].kogo = char[1].strip
      @players[sender].komu = char[2].strip
      @players[sender].kem = char[3].strip
      @players[sender].okom = char[4].strip
      @players[sender].chey = char[5].strip
    else
      return @descr['namealreadyexits']
    end
    @players[sender].sex = char[6].strip
    @db.updateplayer(sender, @players[sender])
    return @descr['gogogo']
  end

  def playerslist()
    str = @descr['listheader']
    i=0
    @players.each { |addr, p|
      str = str+"\n##{i.to_s}: id:#{p.id.to_s}, #{addr}, #{p.name},#{@descr[p.sex]}, #{@descr[p.rights]}, #{@descr[p.ready.to_s]}, #{p.where.to_s}\n"
      i=i+1
    }
    str
  end

  def playeredit(sender, message)
    addr = message.scan(/(?:[-a-z_\.0-9])*@(?:[-a-z])*(?:\.[a-z]{2,4})/)[0]
    cmd = message.sub(addr, "")
    #p addr
    #p cmd
    case cmd
      when /^name\s.+$/
        @locations[cur].name = str.sub(/name\s/, '')
      else
        return "\nsyntax error"
    end
  end

  def playerdelete(message)
    addr = message.strip
    return "bad address" unless @players.key?(addr)
    @players.delete(addr)
    @db.deleteplayer(addr)
    return @descr['ok']
  end

  def giveadminrights(sender, message)
    return @descr['unknownplayer'] unless @players.key?(message)
    return @descr['adminexists'] if @admins.include?(message)
    @players[message].rights = 'admin'
    @db.updateplayer(message, @players[message])
    @admins += [message]
    sendmess(message, @descr.build('giverights', [@players[sender].name])) if @players[sender].ready
    @descr['ok']
  end

  def takeadminrights(sender, message)
    return @descr['unknownplayer'] unless @players.key?(message)
    return @descr['notadmin'] unless @admins.include?(message)
    @players[message].rights = 'player'
    @db.updateplayer(message, @players[message])
    @admins -= [message]
    sendmess(message, @descr.build('takerights', [@players[sender].name])) if @players[sender].ready
    @descr['ok']
  end

  def locationslist(sender)
    p = @players[sender]
    rstr = @descr['llistheader']
    rstr += @descr['lowner'] if p.rights == 'admin'
    i = 0
    count = 0
    @locations.each do |l|

      unless l.nil?
        if l.ownerid == p.id || p.rights == 'admin'
          rstr += "\n#{l.id.to_s}: #{l.name}"
          count += 1
          i += 1
        end

        if p.rights == 'admin'
          lowner = getplayerbyid(l.ownerid)
          name = (lowner != nil) ? lowner.name : "#{l.ownerid}"
          rstr += " (#{name})"
        end
      end

      if i == 108
        i = 0
        sendmess(sender, rstr)
        rstr = @descr['llistheader']
        rstr += @descr['lowner'] if p.rights == 'admin'
      end
    end
    sendmess(sender, rstr+"\ntotal: #{count}")
  end

  def DoTime
# FIXME: переделать время на системный таймер
    Thread.new do
      lch = @time+63
      loop do
        @time += 1
        begin
          if @time >= lch
            lch = @time+63
            @players.each { |addr, p|
              next unless p.ready
              if p.lrealise+p.REALISEINTERVAL < @time
                l = @locations[p.where]
                p.realise?(@time, l.power_place)
              end

              if @time - p.lat > 18*60
                sendmess(addr, @descr['autologout'])
                stop(addr)
              end

              if @time - p.lat >= 9*60 && @time - p.lat <= 10*60
                sendmess(addr, @descr['longtime'])
              end
            }
          end
        rescue
          sendmess($MAINADDR, "error in location events fork:\n" + $!.to_s)
        end
        sleep 1
      end
    end
  end

  def rndloc
    r = 0
    while @locations[r].nil? do
      r = rand(@locations.size)
      unless @locations[r].nil?
        r = 0 unless @locations[r].areflag
      end
    end
    r
  end


  def initialize()
    @gmut = Mutex.new
    @db = MUDDB.new
    @descr = Descriptions.new(@db)
    @players = @db.loadchars()
    @locations = @db.loadmap()
    @admins = @db.loadadmins()
# FIXME: переделать время на системный таймер
    @time = 0
    @need4newloc = 5
    @need4delloc = 5
    @need4eventloc = 10
    @need4players_action = 30
    @need4who = 5
    @need = 3
    DoTime()
    indafork
  end
#	def BooksList(sender,message)
#p = @players[sender]
#l = @locations[p.where]
#out = @descr['booklist']
#return @descr['youneedTerminal'] unless l.name.downcase == 'библиотека'
#i = 0
#while true do
#i += 1
#break unless @descr.present?('book'+i.to_s)
#out += "#{i.to_s}. \"#{@descr['book'+i.to_s].split(')><(')[0]}\"\n"
#end
#out
#end
#def SelectBook(sender,message)
#p = @players[sender]
#l = @locations[p.where]
#return @descr['youneedTerminal'] unless l.name.downcase == 'библиотека'
#return @descr['nobook'] unless @descr.present?('book'+message.strip)
#out = @descr['bookview']
#out += @descr['book'+message].split(')><(')[0]
#out += "\n"
#out += @descr['book'+message].split(')><(')[1]
#out
#end

#def AddBook(sender,message)
#p = @players[sender]
#l = @locations[p.where]
#return @descr['youneedTerminal'] unless l.name.downcase == 'библиотека'
#i = 0
#while true do
#i+=1
#break unless @descr.present?('book'+i.to_s)
#end
#@descr.edit('book'+i.to_s+' '+message)
#@descr['ok']
#end
#def ProhibitFollowing(sender,message)
#p = @players[sender]
#p.followingplayers.each{ |addr|
#p2 = @players[addr]
#p2.followplayer = ''
#sendmess(addr,TextBuild(@descr["PlayerProhibitFollowing"],p2,p) )if p2.ready
#}
#p.followingplayers.clear
#p.AllowFollowing = false
#@descr['ProhibitFollowing']
#end

#def AllowFollowing(sender,message)
#@players[sender].AllowFollowing = true
#@descr['YouAllowFollowing']
#end

#def StopFollow(sender)
#p = @players[sender]
#sender2 = p.followplayer
#return @descr["YouNotFollow"] if sender2 == ''
#p2 = @players[sender2]
#p2.followingplayers.delete(sender)
#p.followplayer = ''
#return TextBuild(@descr["YouStopFollow"],p,p2)
#end

#def Follow(sender,message)
#p = @players[sender]
#l = @locations[p.where]
#sender2 = GetAddrByName(sender,message)
#return @descr['unknownname'] unless sender2
#p2 = @players[sender2]
#return @descr.build("playernothere",[p2.chey]) if p.where != p2.where || !p2.ready
#return TextBuild(@descr["PlayerProhibitFollowing"],p,p2) if !p2.AllowFollowing
#return TextBuild(@descr["playercantfollowplayer"],p,p2) if p.followingplayers.include?(sender2)
#return TextBuild(@descr["YouAlreadyFollow"],p,p2) if p2.followingplayers.include?(sender)
#return TextBuild(@descr["PlayerAlreadyFollow"],p,p2) unless p2.followplayer == ''
#return @descr["YouAlreadyLeading"] unless p.followingplayers.empty?
#o = "\n"
#o += StopFollow(sender) + "\n" unless p.followplayer == ''
#p.followplayer = sender2
#p2.followingplayers.push(sender)
#out = TextBuild(@descr["Following"],p,p2)
#sendmess(sender2, out[1])
#o += out[0]
#o
#end
end

