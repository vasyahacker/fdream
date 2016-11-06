# -*- coding: utf-8 -*-
def LoadCommonCmd(bot, game, type)
  bot.add_command(
      :type => type,
      :syntax => 'цель | target <имя>',
      :description => 'прицелиться, нацелиться',
      :regex => /^((цель)|(target))\s+(#{USER_NAME_REGEX})$/i,
      :is_public => true
  ) do |sender, message|
    game.Target(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'уснуть',
      :description => 'уснуть в забытом сне',
      :regex => /^уснуть$/i,
      :is_public => false
  ) do |sender, message|
    game.Sleep(sender) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'проснуться',
      :description => 'проснуться в забытом сне',
      :regex => /^проснуться$/i,
      :is_public => false
  ) do |sender, message|
    game.Wakeup(sender) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'open | открыть <направление>',
      :description => 'Открыть проход на севере: "открыть с"',
      :regex => /^((open)|(o)|(открыть)|(откр)) ((с)|(ю)|(з)|(в)|(вв)|(вн)|(n)|(s)|(w)|(e)|(u)|(d))$/i,
      :is_public => true
  ) do |sender, message|
    if game.check(sender)
      dir = message
      case message
        when 'с'
          dir = 'n'
        when 'ю'
          dir = 's'
        when 'з'
          dir = 'w'
        when 'в'
          dir = 'e'
        when 'вв'
          dir = 'u'
        when 'вн'
          dir = 'd'
      end

      game.DirectOpenClose(sender, dir, true)
    end
  end

  bot.add_command(
      :type => type,
      :syntax => 'close | закрыть <направление>',
      :description => 'Закрыть проход на севере: "закрыть с"',
      :regex => /^((close)|(cl)|(закрыть)|(з)|(закр)) ((с)|(ю)|(з)|(в)|(вв)|(вн)|(n)|(s)|(w)|(e)|(u)|(d))$/i,
      :is_public => true
  ) do |sender, message|
    if game.check(sender)
      dir = message
      case message
        when 'с'
          dir = 'n'
        when 'ю'
          dir = 's'
        when 'з'
          dir = 'w'
        when 'в'
          dir = 'e'
        when 'вв'
          dir = 'u'
        when 'вн'
          dir = 'd'
      end

      game.DirectOpenClose(sender, dir, false)
    end
  end

  bot.add_command(
      :type => type,
      :syntax => 'inventory | инвентарь | инв | и | i',
      :description => 'показывает ваш инвентарь',
      :regex => /^((inventory)|(i)|(и)|(инв)|(инвентарь))$/i,
      :is_public => true
  ) do |sender, message|
    game.Inventory(sender) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'miscarry | выкинуть | бросить | выбросить <номер>',
      :description => 'выбросить предмет из вашего инвентаря',
      :regex => /^((miscarry)|(выкинуть)|(бросить)|(выбросить))\s[0-9]{1,3}$/i,
      :is_public => true
  ) do |sender, message|
    game.MiscarryObject(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'положить | выложить <номер>',
      :description => 'выложить предмет из вашего инвентаря(то же что и выбросить)',
      :regex => /^((положить)|(выложить))\s[0-9]{1,3}$/i,
      :is_public => true
  ) do |sender, message|
    game.MiscarryObject(sender, message, true) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'take | взять | подобрать | поднять <номер>',
      :description => 'подобрать предмет',
      :regex => /^((take)|(взять)|(вз)|(подобрать)|(поднять))\s[0-9]{1,3}$/i,
      :is_public => true
  ) do |sender, message|
    game.TakeObject(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'give | дать | отдать <номер предмета> <имя игрка>',
      :description => 'передать предмет из вашего инвентаря другому игроку',
      :regex => /^((give)|(дать)|(отдать)|(передать))\s[0-9]{1,3}\s(#{USER_NAME_REGEX})$/i,
      :is_public => true
  ) do |sender, message|
    game.GiveObject2Player(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'mail | письмо',
      :description => "написать письмо: письмо Адольфу:\nПривет, выходи в игру! Жду тебя на почте!",
      :regex => /^((письмо)|(mail))\s+(#{USER_NAME_REGEX}):\s*.+$/im,
      :is_public => true
  ) do |sender, message|
    game.Mail2Player(sender, message) if game.check(sender)
  end


  bot.add_command(
      :type => type,
      :syntax => 'invite <string>',
      :description => 'Послать приглашение другу
Например invite bab@jabber.ru - вышлет по адресу bab@jabber.ru в джабер приглашение типа "Превед тебя приглашают поиграть... блаблабла..."',
      :regex => /^invite\s[A-Za-z_\.0-9]{1,30}@[a-zA-Z0-9\.]{2,40}\.[a-z]{2,4}$/i,
      :is_public => true
  ) do |sender, message|
    game.invite(sender, message) if game.check(sender)
  end

  lockRegex = USER_NAME_REGEX.gsub(/\{[0-9]{1,3},([0-9]{1,3})\}/i) {"{1,#{$1}}"}
  bot.add_command(
      :type => type,
      :syntax => 'look to <player>',
      :description => 'Посмотреть на другого игрока или на руки или на NPC',
      :regex => /^look to (#{lockRegex})$/i,
      :alias => [{:type => type,
                  :syntax => 'l', :regex => /^l (#{lockRegex})$/i},
                 {:type => type,
                  :syntax => 'см <имя>', :regex => /^см (#{lockRegex})$/i},
                 {:type => type,
                  :syntax => 'см на <имя>', :regex => /^см на (#{lockRegex})$/i},
                 {:type => type,
                  :syntax => 'осмотреть <имя>', :regex => /^осмотреть (#{lockRegex})$/i},
                 {:type => type,
                  :syntax => 'смотреть на <имя>', :regex => /^смотреть на (#{lockRegex})$/i},
                 {:type => type,
                  :syntax => 'посмотреть на <имя>', :regex => /^посмотреть на (#{lockRegex})$/i}],
      :is_public => true
  ) do |sender, message|
    if game.check(sender)
      name = message.gsub(/(to )|(на )/i, '').strip
      r = game.look2hands(sender, message) if name == 'руки' || name == 'hands'
      r = game.LookTo(sender, name) unless name == 'руки' || name == 'hands'
    end
    r
  end

  bot.add_command(
      :type => type,
      :syntax => 'who',
      :description => 'Список игроков on-line',
      :regex => /^who$/i,
      :alias => [{:type => type,
                  :syntax => 'кто', :regex => /^[кК]то$/i}],
      :is_public => true
  ) do |sender, message|
    game.who(sender) if game.check(sender) || game.admins.include?(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'использовать | применить <номер>',
      :description => 'использовать предмет',
      :regex => /^((использовать)|(применить))\s[0-9]{1,3}$/i,
      :is_public => true
  ) do |sender, message|
    game.UseObject(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'смс [<Имя>:<текст>]',
      :description => 'послать смс или прочитать (если без параметров)',
      :regex => /^смс\s?.*$/im,
      :alias => [{:type => type, :syntax => 'sms [<Имя>:<текст>]', :regex => /^sms\s?.*$/im}],
      :is_public => true
  ) do |sender, message|
    game.SMS(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'язык к небу',
      :description => 'То же что и смотреть на руки, но при осознанности большей 99',
      :regex => /^язык к небу$/i,
      :alias => [{:type => type,
                  :syntax => 'lts', :regex => /^lts$/i}],
      :is_public => true
  ) do |sender, message|
    game.tongue2sky(sender) if game.check(sender)
  end

end
