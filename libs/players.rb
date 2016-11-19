# -*- coding: utf-8 -*-

####################
#Character - player#
####################
class Player

  attr_accessor :addr, :lat, :sex, :name, :ready,

                :where, :kogo, :komu, :kem,

                :okom, :rights, :descr, :status,

                :chey, :id, :knownlocs, :inventory,

                :AllowFollowing, :followingplayers,

                :followplayer, :state, :lrealise, :sms,

                :sensibleness, :lastlogin, :createdate,
                :realemail, :confirmemailcode, :tmpemail,
                :REALISEINTERVAL, :pwd, :target

  def initialize(name='', kogo='', komu='', kem='', okom='', chey='', sex='', ready=false, where=1, rights="player", descr='', status='')

    @SENSINTERVAL = 27*60
    @REALISEINTERVAL = 27*60
    @id = 0
    @name = name
    @kogo = kogo
    @komu = komu
    @kem = kem
    @okom = okom
    @sex = sex
    @ready = ready
    @where = where
    @rights = rights
    @descr = descr
    @status = status
    @chey = chey

    #last action time
    @lat = 60*60

    #last realise
    @lrealise = -1

    #known locations
    @knownlocs = []


    @inventory = []
    @AllowFollowing = false
    @followingplayers = []
    @followplayer = ''
    @state = ""
    @sms = []
    @sensibleness = 0
    @lastlogin = 0
    @senstime = Time.now.to_i+@SENSINTERVAL
    @createdate = 0
    @realemail = nil
    @confirmemailcode = 0
    @tmpemail = nil
    @addr = nil
    @pwd = nil
    @target = nil
  end

  def AddItem(obj)
    @inventory.push(obj)
  end

  def GetItem(name)
    @inventory.each do |item|
      if item.name == name
        @inventory.delete(item)
        return item
      end
    end
  end

  def male?
    return true if sex == 'male'
    false
  end

  def female?
    return true if sex == 'female'
    false
  end

  def KnownLoc?(loc)
    @knownlocs.include?(loc)
  end

  def FirstTimeHere?
    return false if @knownlocs.include?(@where)
    @knownlocs.push(@where)
    return true
  end

  def realise?(time, in_power_place=false)
    return true if in_power_place
    if time - @lrealise < @REALISEINTERVAL
      if @senstime < Time.now.to_i
        @sensibleness += 1
        @senstime = Time.now.to_i+@SENSINTERVAL
        $gg.sendmess(@addr, "Осознанность +1 (#{@sensibleness})")
      end
      return true
    end

    @sensibleness -= 1
    $gg.sendmess(@addr, "Осознанность -1 (#{@sensibleness})")
    return false
  end

  def is_realise?(time, in_power_place=false)
    return true if in_power_place
    return time - @lrealise < @REALISEINTERVAL
  end
end
