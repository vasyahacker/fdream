# -*- coding: utf-8 -*-
require 'iconv'
require_relative 'players'

#####################################
# NOTE: Game - main objects manager #
#####################################
class Game
  attr_accessor :players, :descr, :admins, :time, :db, :locations

  def check(sender)
    if @players.key?(sender) && @players[sender].ready
      @players[sender].lat = @time
      @players[sender].lrealise = @time if @players[sender].lrealise < 0
      true
    else
      if !@players.key?(sender)
        @players[sender] = Player.new(sender, 'noname',
                                      'noname', 'noname', 'noname',
                                      'noname', 'nosex', false, 693)
        @players[sender].createdate = Time.now.to_i
        #id = @db.addplayer(sender,@players[sender])
        #@players[sender].id = id
      end

      @players[sender].lat = @time
      @players[sender].lrealise = @time if @players[sender].lrealise < 0
      false
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
      return false
    end
    @players[sender].sex = char[6].strip
    return true
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


  def initialize()
    @players = {}
    @locations = []
    @time = 0
  end
end

