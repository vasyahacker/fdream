# -*- coding: utf-8 -*-
def LoadBaseCmd(bot, game, type)

  bot.add_command(
      :type => type,
      :syntax => 'start',
      :description => game.descr['cmdstart'],
      :regex => /^start$/i,
      :alias => [{:type => type,
                  :syntax => 'старт', :regex => /^старт$/i}],
      :is_public => true
  ) do |sender, message|
    game.start(sender) unless game.check(sender)
  end


  bot.add_command(
      :type => type,
      :syntax => 'stop',
      :description => game.descr['cmdstop'],
      :regex => /^stop$/i,
      :alias => [{:type => type,
                  :syntax => 'стоп', :regex => /^стоп$/i}],
      :is_public => true
  ) do |sender, message|
    game.stop(sender) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'north n с север сев',
      :description => game.descr['cmdn'],
      :regex => /^((north)|(n)|(север)|(с))$/i,
      :is_public => true
  ) do |sender, message|
    game.go(sender, 'n') if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'south s ю юг',
      :description => game.descr['cmds'],
      :regex => /^((south)|(s)|(ю)|(юг))$/i,
      :is_public => true
  ) do |sender, message|
    game.go(sender, 's') if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'west w з запад зап',
      :description => game.descr['cmdw'],
      :regex => /^((west)|(з)|(запад)|(w))$/i,
      :is_public => true
  ) do |sender, message|
    game.go(sender, 'w') if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'east e в восток вост',
      :description => game.descr['cmde'],
      :regex => /^((east)|(в)|(восток)|(e))$/i,
      :is_public => true
  ) do |sender, message|
    game.go(sender, 'e') if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'up u вв вверх наверх',
      :description => game.descr['cmdu'],
      :regex => /^((up)|(вв)|(вверх)|(наверх)|(u))$/i,
      :is_public => true
  ) do |sender, message|
    game.go(sender, 'u') if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'down d вн вниз',
      :description => game.descr['cmdd'],
      :regex => /^((down)|(вн)|(вниз)|(d))$/i,
      :is_public => true
  ) do |sender, message|
    game.go(sender, 'd') if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'карта | map',
      :description => 'ссылка на карту игры',
      :regex => /^((map)|(карта))$/i,
      :is_public => true
  ) do |sender, message|
    "http://game.magicfreedom.com/map.html" if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'return | возврат',
      :description => 'переместится в стартовую локацию (двор дома)',
      :regex => /^((return)|(возврат))$/i,
      :is_public => true
  ) do |sender, message|
    game.Return(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'look',
      :description => 'Осмотреться - показывает описание локации в которой вы находитесь',
      :regex => /^look$/i,
      :alias => [{:type => type,
                  :syntax => 'l', :regex => /^l$/i},
                 {:type => type,
                  :syntax => 'см', :regex => /^[Сс]м$/i},
                 {:type => type,
                  :syntax => 'осмотреться', :regex => /^[Оо]смотреться$/i},
                 {:type => type,
                  :syntax => 'смотреть', :regex => /^[Сс]мотреть$/i}],
      :is_public => true
  ) do |sender, message|
    game.look(sender) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'revision',
      :regex => /^revision$/,
      :is_public => true
  ) do |sender, message|
    "REVISION: #{`git log --pretty=format:'%h - %ar(%ad): %s' -n 1`}"
  end
end
