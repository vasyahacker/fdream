# -*- coding: utf-8 -*-
def LoadBuildCmd(bot, game, type)

  bot.add_command(
      :type => type,
      :syntax => 'linsert <направление>',
      :description => 'Вставить локацию между местом где вы находитесь и местом в указанном направлении.',
      :regex => /^linsert ((n)|(s)|(w)|(e)|(u)|(d))$/i,
      :is_public => true
  ) do |sender, message|
    game.insertlocation(sender, message.downcase) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'llist',
      :description => game.descr['cmdllist'],
      :regex => /^llist$/i,
      :is_public => true
  ) do |sender, message|
    game.locationslist(sender) if game.check(sender)
    nil
  end


  bot.add_command(
      :type => type,
      :syntax => 'ledit <string>',
      :description => game.descr['cmdledit'],
      :regex => /^ledit\s.+$/i,
      :is_public => true
  ) do |sender, message|
    game.locedit(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'ladd <direction> [<name>]',
      :description => 'Создать локацию, ladd n - создаст новую локацию в северном направлении если до этого там было пусто; ladd n туалет - создаст туалет в северном направлении',
      :regex => /^ladd ([nsweud](\s.+)?)$/i,
      :is_public => true
  ) do |sender, message|
    game.newlocation(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'ldel <direction>',
      :description => game.descr['cmdldel'],
      :regex => /^ldel ((n)|(s)|(w)|(e)|(u)|(d))$/i,
      :is_public => true
  ) do |sender, message|
    game.dellocation(sender, message.downcase) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'lxml4client',
      :description => game.descr['cmdlxml4client'],
      :regex => /^lxml4client$/i,
      :is_public => true
  ) do |sender, message|
    game.lxml4client(sender) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'redirect',
      :description => game.descr['cmdredirect'],
      :regex => /^redirect\s[nsweud]\s[0-9]{1,4}$/i,
      :is_public => true
  ) do |sender, message|
    game.redirect(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'createkey <направление> <Кточто,Когочего,Комучему,Когочто,Кемчем,(0)ком(о)чём>',
      :description => 'Создать ключ: "createkey n ключ,ключа,ключу,ключ,ключем,ключе", вместо нескольких имен через запятую допускается ввести только одно.',
      :regex => /^createkey ((n)|(s)|(w)|(e)|(u)|(d)) .+$/i,
      :is_public => true
  ) do |sender, message|
    game.CreateKey(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'lchown [all] <имя>',
      :description => 'назначить владельца текущей локации (all - передать все локации)',
      :regex => /^lchown\s(all\s)?#{USER_NAME_REGEX}$/i,
      :is_public => true
  ) do |sender, message|
    game.lchown(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'levents <параметры> <значения>',
      :description => 'редактирование событий в текущей локации
    
    levents - выводит список событий, принадлежащих текущей локации
    
    levents add 4 текст - добавит событие, которое будет происходить каждые 4 минуты
    
    levents edit 1 текст - редактирует событие с номером 1
    
    levents del 1 - удалит событие под номером 1
    
    Обратите внимание на то что события начнут работать только после того как их на каждый период будет добавлено не меньше 3, то есть на каждые 2 минуты надо добавить минимум 3 события после чего каждые 2 минуты будет происходить только одно событие, выбранное из существующих случайным образом.',
      :regex => /^levents\s?.*$/m,
      :is_public => true
  ) do |sender, message|
    game.levents(sender, message) if game.check(sender)
  end

end
