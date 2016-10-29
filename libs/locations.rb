# -*- coding: utf-8 -*-
###################
# Map - location  #
###################
class Location
# TODO: добавить массив для id или адресов игроков, которые находятся в текущей локации, как у объектов
  attr_accessor :name, :descr, :nid, :sid, :wid, :eid, :uid, :did,
                :nod, :sod, :wod, :eod, :uod, :dod,
                :n, :s, :w, :e, :u, :d, :objects, :id, :ownerid, :areflag,
                :events, :power_place, :code,
                :desc_close_n, :desc_close_s, :desc_close_w,
                :desc_close_e, :desc_close_u, :desc_close_d,
                :players

  def initialize(name="Новая локация", descr="Тут ничего нет.",
                 nid='', sid='', wid='', eid='', uid='', did='',
                 nod='', sod='', wod='', eod='', uod='', dod='',
                 n=0, s=0, w=0, e=0, u=0, d=0)
    @id = 0
    @name = name
    @descr = descr
    @nid = nid
    @sid = sid
    @wid = wid
    @eid = eid
    @uid = uid
    @did = did
    @nod = nod
    @sod = sod
    @wod = wod
    @eod = eod
    @uod = uod
    @dod = dod
    @n = n
    @s = s
    @w = w
    @e = e
    @u = u
    @d = d
    @objects = []
    @players = []
    @ownerid = 0
    @areflag = false
    @events = []
    @power_place = false
    @code = nil
    @desc_close_n = nil
    @desc_close_s = nil
    @desc_close_w = nil
    @desc_close_e = nil
    @desc_close_u = nil
    @desc_close_d = nil
  end

  def powerplace?
    @power_place
  end

  def numexits?
    n = 6
    n -= 1 if @n == 0
    n -= 1 if @s == 0
    n -= 1 if @w == 0
    n -= 1 if @e == 0
    n -= 1 if @u == 0
    n -= 1 if @d == 0
    n
  end

  def noexits?
    (@n == 0 && @s == 0 && @w == 0 && @e == 0 && @u == 0 && @d == 0)
  end

  def [](index)
    case index
      when "nid"
        @nid
      when "sid"
        @sid
      when "wid"
        @wid
      when "eid"
        @eid
      when "uid"
        @uid
      when "did"
        @did
      when "nod"
        @nod
      when "sod"
        @sod
      when "wod"
        @wod
      when "eod"
        @eod
      when "uod"
        @uod
      when "dod"
        @dod
      when "n"
        @n
      when "s"
        @s
      when "w"
        @w
      when "e"
        @e
      when "u"
        @u
      when "d"
        @d
    end
  end

  def []=(index, value)
    case index
      when "nid"
        @nid = value
      when "sid"
        @sid = value
      when "wid"
        @wid = value
      when "eid"
        @eid = value
      when "uid"
        @uid = value
      when "did"
        @did = value
      when "nod"
        @nod = value
      when "sod"
        @sod = value
      when "wod"
        @wod = value
      when "eod"
        @eod = value
      when "uod"
        @uod = value
      when "dod"
        @dod = value
      when "n"
        @n = value
      when "s"
        @s = value
      when "w"
        @w = value
      when "e"
        @e = value
      when "u"
        @u = value
      when "d"
        @d = value
    end
  end

  def indescr(direct, player)
    case direct
      when "n"
        str = @sid
      when "s"
        str = @nid
      when "w"
        str = @eid
      when "e"
        str = @wid
      when "u"
        str = @did
      when "d"
        str = @uid
      else
        return "bad direction!"
    end
    str = str.gsub('~kto~', player.name)
    str = str.gsub('~kogo~', player.kogo)
    str = str.gsub('~komu~', player.komu)
    str = str.gsub('~kem~', player.kem)
    str = str.gsub('~okom~', player.okom)
    str = str.gsub('~chey~', player.chey)
    descr = str.gsub(/(\[\[[^\[\]]+\]\])|([\{\}])/, '') if player.male?
    descr = str.gsub(/(\{\{[^\{\}]+\}\})|([\[\]])/, '') if player.female?
    descr = descr.split(')><(')
    return nil if descr[1].nil?
    descr
  end

  def outdescr(direct, player)
    case direct
      when "n"
        str = @nod
      when "s"
        str = @sod
      when "w"
        str = @wod
      when "e"
        str = @eod
      when "u"
        str = @uod
      when "d"
        str = @dod
      else
        return "bad direction!"
    end
    str = str.gsub('~kto~', player.name)
    str = str.gsub('~kogo~', player.kogo)
    str = str.gsub('~komu~', player.komu)
    str = str.gsub('~kem~', player.kem)
    str = str.gsub('~okom~', player.okom)
    str = str.gsub('~chey~', player.chey)
    descr = str.gsub(/(\[\[[^\[\]]+\]\])|(\{\{)|(\}\})/, '') if player.male?
    descr = str.gsub(/(\{\{[^\{\}]+\}\})|(\[\[)|(\]\])/, '') if player.female?
    descr = descr.split(')><(')
    return nil if descr[1].nil?
    descr
  end

  def addEvent(times, descr, id=0)
    newevent = LocEvent.new(times, descr)
    newevent.id = id
    @events.each do |e|
      if e.times == times
        newevent.stime = e.stime
        break
      end
    end
    @events.push(newevent)
  end

  def getEvents
    evts = []
    events.each do |e|
      evts.push(e.descr) if e.ready?
    end
    return evts if evts.size > 0
    nil
  end

  def delEvent(n)
    id = @events[n].id
    @events.delete_at n
    id
  end

end

class LocEvent
  attr_accessor :times, :descr, :stime, :id

  def initialize(times, descr)
    @times = times
    @stime = Time.now.to_i # + 60*times
    @descr = descr
    @id = 0
  end

  def ready?
    if Time.now.to_i >= @stime
      @stime = Time.now.to_i + 60*times
      return true
    end
    return false
  end
end
