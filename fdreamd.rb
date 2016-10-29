# -*- coding: utf-8 -*-
# NOTE: Забытый сон,MUD-бот, игра, ммо рпг настроенная на работу через интерфейс интернет мессенжеров..
#$KCODE = "utf-8"
#$LOAD_PATH.unshift('./libs/jabber/')
#require 'unicode'
require 'cgi'
require 'rubygems'
#require 'sqlite3-ruby'
require 'sqlite3'
require 'xmpp4r/roster'
require 'xmpp4r'
require './libs/jabber/xmpp4r-simple.rb'
#require 'xmpp4r-simple'
#require 'xml/libxml'
require 'arrayfields'
require 'thread'
require 'digest/md5'
#require "libs/unicodefix.rb"
require './libs/tserver.rb'
require './libs/jabber/bot.rb'
require './libs/db.rb'
require './libs/players.rb'
require './libs/locations.rb'
require './libs/descriptions.rb'
require './libs/objects.rb'
require './libs/game.rb'

require "./libs/cmdsettings.rb"
require "./libs/cmdbase.rb"
require "./libs/cmdcommon.rb"
require "./libs/cmdbuild.rb"
require "./libs/cmdsocials.rb"
require "./libs/cmdadm.rb"

GC.enable

$DreamInDream = Array.new(0)
# TODO: вынести настройки в конфиг
# For send debug info
$MAINADDR = "JID"

# For send email
$SMTP_LOGIN = "LOGIN"
$SMTP_PWD = "PASS"
#Jabber::debug = true
game = Game.new

$gg = game
# Configure a public bot
config = {
  :name      => 'MUDBot',
  :jabber_id => 'JID',
  :password  => 'PASS',
  :master    => game.admins,
  :is_public => true,
  :status    => 'play?',
  :presence  => :chat,
  :priority  => 10
}

# Create a new bot
bot = Jabber::Bot.new(config)
LoadSettingsCmd( bot, game, "настройки" )
LoadBaseCmd( bot, game, "базовые" )
LoadCommonCmd( bot, game, "основные" )
LoadAdmCmd( bot, game, "администраторские" )
LoadBuildCmd( bot, game, "строительство" )
LoadSocCmd( bot, game, "социалы" )

#reconnecttime = 6000
#bot.add_command(
#  :syntax      => 'интервал_переподключения',
#  :description => game.descr['reconnecttime'],
#  :regex       => /^интервал_переподключения\s[0-9]{3,5}$/i,
#  :is_public   => false
#) do |sender, message|
#    if game.check(sender)
#		reconnecttime = message.to_i
#		"установлен интервал автоматического переподключения сервера в #{message} секунд"
#	end
#end

#bot.add_command(
#  :syntax      => 'allow following | разрешить следовать за мной | разрешить следовать',
#  :description => "разрешает другим игрокам следовать за вами",
#  :regex       => /^(([Рр]азрешить следовать за мной)|([Рр]азрешить следовать)|(allow following))$/i,
#  :is_public   => false
#) do |sender, message|
# 	game.AllowFollowing(sender,message) if game.check(sender)
#end

#bot.add_command(
#  :syntax      => 'prohibit following | нельзя больше следовать за мной | запретить следовать | нельзя следовать',
#  :description => "запрещает другим игрокам следовать за вами",
#  :regex       => /^(([Нн]ельзя больше следовать за мной)|([Зз]апретить следовать)|([Нн]ельзя следовать)|(prohibit following))$/i,
#  :is_public   => false
#) do |sender, message|
# 	game.ProhibitFollowing(sender,message) if game.check(sender)
#end

#bot.add_command(
#  :syntax      => 'follow | fol | следовать за| след за <имя>',
#  :description => "следовать за игроком - то есть вы будите автоматически двигаться за ним куда бы он не направился",
#  :regex       => /^(([Сс]лед)|([Сс]ледовать)|([Сс]лед за)|([Сс]ледовать за)|(fol)|(follow))\s([[:alnum:]]{3,30})$/i,
#  :is_public   => false
#) do |sender, message|
# 	game.Follow(sender,message.sub(/^за\s/,'')) if game.check(sender)
#end

#bot.add_command(
#  :syntax      => 'перестать следовать',
#  :description => "перестать следовать за игроком",
#  :regex       => /^[Пп]ерестать следовать$/i,
#  :is_public   => false
#) do |sender, message|
# 	game.StopFollow(sender) if game.check(sender)
#end

#bot.add_command(
#  :syntax      => 'список',
#  :description => 'показывает список литературы на терминале в библиотеке',
#  :regex       => /^[Сс]писок$/i,
#  :is_public   => true
#) do |sender, message|
#    game.BooksList(sender,message) if game.check(sender)
#end

#bot.add_command(
#  :syntax      => 'выбрать <номер книги>',
#  :description => 'показывает книгу на терминале в библиотеке',
#  :regex       => /^[Вв]ыбрать\s[0-9]{1,3}$/i,
#  :is_public   => true
#) do |sender, message|
#    game.SelectBook(sender,message) if game.check(sender)
#end

#bot.add_command(
#  :syntax      => 'добавить_книгу <название>)><(<текст>',
#  :description => 'добавляет книгу в библиотеку',
#  :regex       => /^добавить_книгу\s[\.\,\"a-zЁёА-Яа-яA-Z0-9\s]{1,99}\)><\(.+$/m,
#  :is_public   => false
#) do |sender, message|
#    game.AddBook(sender,message) if game.check(sender)
#end

bot.notcommand{ |addr,txt| 
	if game.check(addr)
#		game.ParseCommands(addr,txt) 
		mess = game.say(addr,txt)
#		bot.deliver(addr,mess)unless mess.nil?
		bot.sendstack.push([addr,mess])unless mess.nil?
	end
}
repeat_thread = Thread.new do
  oldstatus = ''
  loop {

#require 'ruby-debug'
#debugger
# FIXME: переделать время на системный таймер
#    game.DoTime
      bot.masters = game.admins if bot.masters != game.admins
      if oldstatus != game.status
          bot.status = game.status
          oldstatus = game.status
      end
#    nstat = `netstat -4|grep 'xmpp-client ESTABLISHED'`
#    unless nstat.length > 0
sleep 18
    unless bot.jabber.connected?
      bot.jabber.disconnect
	sleep 1
      bot.jabber.connect
      bot.status = game.status
      oldstatus = game.status
    end
 #   sleep 27
  }
end

game.send{ |addr,txt|
	bot.sendstack.push([addr,txt])
}
bot.repeatcalls
GC.start
bot.connect
