# -*- coding: utf-8 -*-
###############
#Objects/items#
###############


class Obj

  attr_accessor :id, :type, :names, :names_string, :data, :descriptions,
                :static, :id_parent, :parent_type, :number_of_uses,
                :code, :adjectives, :descr, :id_owner
  attr_reader :silence_flag

  def initialize(names, type)
    @id = 0
    @type = type
    @names = names.split(',')
    @names_string = names
    @data = ''
    @descriptions = ""
    @descr = ""
    @static = false
    @id_parent = 0
    @id_owner = 0
    @parent_type = 'player'
    @number_of_uses = 0
    @code = ''
    @thread = nil
    @codealive = true
    @listeneventcode = nil
    @incomingplayercode = nil
    @sex = 'male'
    @silence_flag = false
    @adjectives = ""
  end

  def KtoChto
    return @names[0] if @names.size > 0
    @names_string
  end

  def KogoChego
    return @names[1] if @names.size > 1
    @names_string
  end

  def KomuChemu
    return @names[2] if @names.size > 2
    @names_string
  end

  def KogoChto
    return @names[3] if @names.size > 3
    @names_string
  end

  def KemChem
    return @names[4] if @names.size > 4
    @names_string
  end

  def OKomOChom
    return @names[5] if @names.size > 5
    @names_string
  end

  def showtoplayer(sender, message)
    return if @parent_type=="player" and @type == 'NPC'
    $gg.sendmess(sender, message)
  end

  def showtoall(sender, message)
    return if @parent_type == "player" and @type == 'NPC'
    if @parent_type == "player"
      p = $gg.getplayerbyid @id_parent
      where = p.where
    else
      where = @id_parent
    end
    $gg.showtoall(sender, message, where)
  end

  def incomingplayer(sender, p)
    @incomingplayercode.call(sender, p) unless @incomingplayercode.nil?
  end

  def listen(sender, message)
    Thread.new do
      begin
        @listencode.call(sender, message) unless @listencode.nil?
      rescue => detail
        if @parent_type == 'player'
          p = $gg.getplayerbyid(@id_parent)
          cont = "player(#{p.name}) backpack in loc ##{p.where.to_s}"
        else
          cont = "location \##{@id_parent.to_s}"
        end

        mess = "\n# # #\nERROR: #{$!.to_s}\nin listen obect code \""+
            KtoChto()+"\" in "+cont+"\n# # #"

        $gg.sendmess($MAINADDR, mess)
        $stderr.puts "\n[#{Time.now.to_s}]: \n[objects] listen: #{$!.to_s}\n#{mess}\n"+detail.backtrace.join("\n")
      end
    end
  end

  def saveself()
    $gg.db.updateobject(self)
  end

  def listenevent(&eventcode)
    @listencode = eventcode
  end

  def incomingplayerevent(&eventcode)
    @incomingplayercode = eventcode
  end

  def runfork()
    killfork
    @thread = Thread.new do
      begin
        eval(@code)
      rescue => detail
        if @parent_type == 'player'
          p = $gg.getplayerbyid(@id_parent)
          cont = "player(#{p.name}) backpack in loc ##{p.where.to_s}"
        else
          cont = "location \##{@id_parent.to_s}"
        end

        mess = "\n# # #\nERROR: #{$!.to_s}\nin embeded obect code \""+
            KtoChto()+"\" in "+cont+"\n# # #"

        $gg.sendmess($MAINADDR, mess)
        $stderr.puts "\n[#{Time.now.to_s}]: \n[objects] runfork: #{$!.to_s}\n#{mess}\n"+detail.backtrace.join("\n")
      end
    end
  end

  def killfork
    @listencode = nil
    return if @thread.nil? || !@thread.alive?
    @codealive = false
    i = 10
    while @thread.alive? do
      i-=1
      sleep 1
      @thread.kill if i == 0
    end
    @codealive = true
  end

  def action(txt, sender2=false)
    return if @parent_type == 'player' and @type == 'NPC'
    if sender2 != false
      p2 = (sender2) ? $gg.players[sender2] : sender2
      out = $gg.TextBuild(txt, p2)
      if out.class == Array
        showtoplayer(sender2, out[1])
        showtoall(sender2, out[0])
      end
    else
      showtoall("", txt)
    end
  end

  def getname(sender)
    $gg.players[sender].name
  end

  def use
    if @code != ''
      runfork()
      return true
    else
      return false
    end
  end
end

class NPC < Obj
  attr_accessor :state, :followingplayers, :sms, :sex
  alias :name :KtoChto
  alias :chey :KogoChego
  alias :komu :KomuChemu
  alias :kogo :KogoChto
  alias :kem :KemChem
  alias :okom :OKomOChom
  alias :where :id_parent

  def ready
    true
  end

  def where
    return if @parent_type == 'player'
    @id_parent
  end

  def where=(val)
    @id_parent = val
  end

  def male?
    (@sex == 'male') ? true : false
  end

  def female?
    (@sex == 'female') ? true : false
  end

  def descr
    @descriptions
  end

  def realise?(time, pp)
    true
  end

  def action(txt, sender2=false)
    return if @parent_type == 'player' and @type == 'NPC'
    p2 = (sender2) ? $gg.players[sender2] : sender2
    out = $gg.TextBuild(txt, self, p2)
    if out.class == Array && sender2 != false
      showtoplayer(sender2, out[1])
      showtoall(sender2, out[0])
    else
      showtoall("", out)
    end
  end

  def say(message, sender=false)
    return if @parent_type == 'player'
    $gg.say(self, ((sender) ? getname(sender)+": " : "") + message)
  end

  def db_open
    @db = SQLite3::Database.new("db/obj_#{@id}.db")
  end

  def quote(s)
    s.force_encoding('utf-8').gsub(/'/, "''") unless s == nil || s == []
  end

  def kick_noobs(from, to)
    return if @parent_type == 'player'
    $gg.players.each { |addr, p|
      if p.ready && p.where == from
        $gg.recall(addr, to, true) unless p.realise?($gg.time)
      end
    }
  end

  def moveplayers(from, to)
    return if @parent_type == 'player'
    $gg.moveplayers("", from, to)
  end

  def moveplayer(sender, to)
    return if @parent_type == 'player'
    $gg.recall(sender, to, true)
  end

  def recall(to)
    return if @parent_type == 'player'
    l1 = $gg.locations[@id_parent]
    l2 = $gg.locations[to]
    @id_parent = to
    l1.objects.delete_if { |x| x.id == @id }
    l2.objects.push self
    saveself
  end

  def go(direct)
    $gg.go(self, direct) unless @parent_type == 'player'
  end
end

class CardsPack

  class Cards

    class Card
      attr_accessor :value, :type, :access, :id, :svert

      def initialize(v="", t="")
        @value = v
        @type = t
        @access = false
        @id = 0
        @svert = 0
      end

      def clear
        @value = ""
        @type = ""
        @access = false
        @svert = 0
      end
    end

    attr_accessor :pack, :lastinsertid, :lastsvertid

    def initialize
      @lastinsertid = 0
      @lastsvertid = []
      @pack = []
      36.times { @pack.push(Card.new()) }
      init
#		clear
    end

    def init
      @pointer = 0
      p = 0
      for v in ["6", "7", "8", "9", "10", "В", "Д", "К", "Т"]
        for t in ["к", "ч", "б", "п"]
          @pack[p].value = v
          @pack[p].type = t
          @pack[p].access = true
          p = p+1
        end
      end
    end

    def clear
      @pack.clear
#each{|c|c.clear}
      @pointer = 0
      @lastinsertid = 0
    end

    def show
      out = ""
      @pack.each do |c|
        if c.access
          out += "#{c.value}#{c.type}"
          out += "(#{c.svert.to_s})" if c.svert > 0
          out += " "
        end
      end
      return out
    end

    def shuffle
      @pack.replace @pack.sort_by { rand }
      0.upto(35) { |i| @pack[i].id=i }
    end

    def add(from)
      n = from.sub
      return n if n == false
      @pack.push n
      @lastinsertid = n.id
      return true
    end

    def sub
      return false if @pointer > 35
      ret = @pack[@pointer].clone
      @pointer += 1
      return ret
    end

    def svertka
      return false if @pack.size < 3
      0.upto(@pack.size-3) do |i|
        if ((@pack[i].value == @pack[i+2].value ||
            @pack[i].type == @pack[i+2].type))
          @lastsvertid[0] = @pack[i].id
          @lastsvertid[1] = @pack[i+1].id
          @pack.delete_at i
          return @lastinsertid
        end
      end
      return false
    end

    def copy(from)
      0.upto(35) { |i| @pack[i] = from.pack[i].clone }
    end

    def maxs
      m = 0
      @pack.each { |c|
        m = c.svert if m < c.svert
      }
      return m
    end

    def showcard(id)
      out = @pack[id].value
      out += @pack[id].type
      return out
    end
  end

  def Doit(sens)
    d = Cards.new
    e = Cards.new
    r = Cards.new
    step = sens
    out = "Ты берешь колоду карт и хорошо перемешиваешь... затем начинаешь терпеливо раскладывать пасьянс Медичи..."
    flag = true
    while flag && step > 0 do
      step -= 1
      r.init
      d.clear
      r.shuffle
      e.copy(r);
      while d.add(r) do
#				print "\nВыкладываем из колоды на стол следующую карту ",E.showcard(D.lastinsertid)
        while true do
          #					print "\nНа столе: ",D.show
          id = d.svertka
          if id == false
            #						print " не найдено сверток..."
            break
          end
#					print "\nнакладываем ",E.showcard(D.lastsvertid[1])," на ",E.showcard(D.lastsvertid[0])
          e.pack[id].svert += 1
        end
      end
      flag = (d.pack.size == 2) ? false : true
    end
    out += "\nВ итоге остались следующие карты:\n"
    out += d.show
    if flag
      out += "\nЖаль.. колода не свернулась..."
    else
      out += "\nКолода свернулась!\n Цепочка выглядит следующим образом: "
      out += e.show
      out += "\nВ скобках показана мощность карты(сколько из-за нее произошло сверток) Максимальная мощность "+e.maxs.to_s
    end
    out
  end
end

class Rune < Obj

  def recall()
    if $gg.locations[@data.to_i].nil?
      showtoplayer(addr, "Место, куда ты собираешся попасть с помощью #{KogoChego()} больше не существует.")
      return
    end
    p = $gg.getplayerbyid @id_parent
    addr = $gg.players.key(p)
    l = $gg.locations[@data.to_i]
    unless l.areflag
      showtoplayer(addr, "Место, куда ты собираешься попасть с помощью #{KogoChego()} защищено от  телепортаций и случайных перемещений.")
      return
    end
    action "~kto~ закрыл[а] глаза и исчез[ла].)><(Ты закрыл[а] глаза и стал[а] вспоминать все что тебе известно о месте, известном тебе как \"#{l.name}\", но детали получалось вспоминать только обрывками, затем ты нащупал[а] в кармане нужную руну телепорта и сильно сжал[а] ее в руке. В тот же момент перед твоим внутренним взором предстало это место во всех деталях. Мгновенье спустя ты с удивлением обнаружил[а] что твои глаза уже не закрыты и ты просто смотришь на то что только что себе представлял[а].", addr
    p.where = @data.to_i
    action "Ты случайно замечаешь что здесь, рядом с тобой, уже находится ~kto~, но когда он[а] тут появил{ся}[ась] вспомнить не можешь.)><(#{$gg.look(addr)}", addr
  end

  def mark()
    p = $gg.getplayerbyid @id_parent
    addr = $gg.players.key(p)
    l = $gg.locations[p.where]
    unless l.areflag
      showtoplayer(addr, "Это место защищено от  телепортаций и случайных перемещений.")
      return
    end
    action '~kto~ осмотрел{ся}[ась] вокруг, затем достал[а] из кармана какую-то деревянную дощечку и крепко сжал[а] ее закрыв при этом глаза на несколько секунд. После чего ты почувствовал легкий энергетический всплеск вокруг себя.)><(Ты осмотрел{ся}[ась] вокруг, и постарал{ся}[ась] запомнить это место как можно детальнее, затем достал[а] из кармана чистую руну телепорта и крепко сжал[а] ее, закрыв при этом глаза, концентрируясь только на этом месте. В следующий миг ты почувствовал[а] как руна в твоей руке  нагрелась и вырезанный на ней узор стал меняться, затем руна остыла. Ты понимаешь что руна теперь принадлежит этому месту.', addr
    @descr = @descr+"\n Ты чувствуешь что этот предмет связан с местом, под названием «#{l.name}»"
    @data = p.where
    saveself
  end

  def use()
    if $gg.isNumeric(@data)
      recall()
    else
      mark()
    end
  end

end
