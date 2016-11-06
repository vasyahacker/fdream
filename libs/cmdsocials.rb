# -*- coding: utf-8 -*-
def LoadSocCmd(bot, game, type)

  bot.add_command(
      :type => type,
      :syntax => 'произвольное',
      :description => 'Выполнить произвольное действие.
Пример: "*ухмыльнулся*" покажет всем "Петя ухмыльнулся"
    ',
      :regex => /^\*(.+)\*$/,
      :is_public => true
  ) do |sender, message|
    game.Social('FreeAction', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'поцеловать :-* <имя>',
      :description => 'Поцеловать игрока',
      :regex => /^((поцеловать)|(:\-\*))\s+#{USER_NAME_REGEX}$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Kiss', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'сесть',
      :description => 'сесть на пол, на землю',
      :regex => /^сесть$/i,
      :is_public => true
  ) do |sender, message|
    game.Social('SitDown', sender, message, true) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'лечь',
      :description => 'лечь на пол, на кровать итп',
      :regex => /^лечь$/i,
      :is_public => true
  ) do |sender, message|
    game.Social('LieDown', sender, message, true) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'встать',
      :description => 'встать',
      :regex => /^встать$/i,
      :is_public => true
  ) do |sender, message|
    game.Social('StandUp', sender, message, true) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'указать | показать на <имя>|<направление>',
      :description => 'указать на игрока или в направлении',
      :regex => /^(указать)|(показать)( на)? ((#{USER_NAME_REGEX})|(север)|(юг)|(запад)|(восток)|(верх)|(вверх)|(вниз)|(с)|(ю)|(з)|(в)|(вв)|(вн))$/i,
      :is_public => true
  ) do |sender, message|
    game.SpecifyTo(sender, message.gsub(/(на )/i, '').strip) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'обнять <имя>[: текст]',
      :description => 'обнять игрока',
      :regex => /^обнять #{USER_NAME_REGEX}:?\s?.*$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Clasp', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'плакать|заплакать|всплакнуть[: текст]',
      :description => 'заплакать...',
      :regex => /^((заплакать)|(плакать)|(всплакнуть)|(:'\()):?\s?.*$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Tear', sender, message) if game.check(sender)
  end


  bot.add_command(
      :type => type,
      :syntax => 'улыбка|улыбаться|улыбнуться|=)|:)|:-) [<имя>]: <текст>',
      :description => 'Улыбаться',
      :regex => /^((улыбка)|(улыбаться)|(улыбнуться)|(=[\)]{1,9})|(:[\)]{1,9})|(:-[\)]{1,9})|([\)]{1,9}))\s?(.*)$/i,
      :is_public => true
  ) do |sender, message|
    game.Social('Smile', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'смутиться|смущение|:-[ [<имя>]: <текст>',
      :description => 'выразить смущение',
      :regex => /^((смутиться)|(смущение)|(:-\[))\s?(.*)$/i,
      :is_public => true
  ) do |sender, message|
    game.Social('Confus', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'ответить|ответ|отв [<имя>]: <текст>',
      :description => 'ответить',
      :regex => /^((ответить)|(ответ)|(отв))\s.+$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Answer', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'загрустить|грустить|грусть|=(|:(|:-( [<имя>]: <текст>',
      :description => 'Грустить',
      :regex => /^((загрустить)|(грустить)|(грусть)|(=[\(]{1,9})|(:[\(]{1,9})|(:-[\(]{1,9})|([\(]{1,9}))\s?(.*)$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Sadness', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'петь [<имя>]: <текст песни>',
      :description => 'Петь',
      :regex => /^петь\s.+$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Sing', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'хлопнуть|похлопать <имя>[:<текст>]',
      :description => 'Похлопать игрока по плечу',
      :regex => /^(хлопнуть)|(похлопать)\s#{USER_NAME_REGEX}:?\s?.*$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Slap', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'хохотать смех смеяться ржать :-D :D :-> :> [<имя>][<:текст>]',
      :description => 'Смеяться',
      :regex => /^((хохот)|(хохотать)|(смех)|(смеяться)|(ржать)|(:-D)|(:D)|(:>)|(:->))\s?.*$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Bugaga', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'whisper шепот шепнуть шептать <имя>:<текст>',
      :description => 'шепот (приватное сообщение)',
      :regex => /^((whisper)|(шепот)|(шепнуть)|(шептать))\s#{USER_NAME_REGEX}:\s?.+$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Whisper', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'rejoice радость радоваться *YAHOO* [<имя>][:<текст>]',
      :description => 'радостно чтото сказать или просто обрадоваться',
      :regex => /^((rejoice)|(радость)|(радоваться)|(\*YAHOO\*))\s?.*$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Rejoice', sender, message) if game.check(sender)
  end


  bot.add_command(
      :type => type,
      :syntax => 'wink подмигнуть ;) ;-) [<имя>][<:текст>]',
      :description => 'Подмигнуть комуто или просто так',
      :regex => /^((wink)|(подмигнуть)|(;\))|(;-\)))\s?.*$/im,
      :is_public => true
  ) do |sender, message|
    game.Social('Wink', sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'крик/кричать <строка>',
      :description => 'ваш крик услышат в соседних локациях',
      :regex => /^(крик)|(кричать)\s.+$/im,
      :is_public => true
  ) do |sender, message|
    game.Shout(sender, message) if game.check(sender) && !message.nil?
  end

end
