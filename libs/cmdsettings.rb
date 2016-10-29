# -*- coding: utf-8 -*-
def LoadSettingsCmd(bot, game, type)

  bot.add_command(
      :type => type,
      :syntax => 'charcreate <string>',
      :description => 'Чтобы войти в игру, нужно задать своему персонажу некоторые параметры.
Для начала введите команду:
"charcreate ваше имя, имя отвечающее на вопрос кого позвать?, имя отвечающее на вопрос кому сказать?, имя отвечающее на вопрос с кем встретиться?, имя отвечающее на вопрос о ком рассказать?, имя отвечающее на вопрос чей трансглюкатор?, male или female".

Где male female - задает ваш пол - мужской или женский.
Обратите внимание на то, что пробелы и в имени не допускаются. 
Имя должно состоять не менее чем из 3 букв.

Пример: charcreate Петя, Петю, Пете, Петей, Пете, Пети, male

После этого можно начинать играть с команды start.
Эта команда так же используется для смены имени.',
      :regex => /^charcreate .*$/i,
      :is_public => true
  ) do |sender, message|
    if message =~ /^[[:alnum:]]{3,30}\,\s?[[:alnum:]]{3,30}\,\s?[[:alnum:]]{3,30}\,\s?[[:alnum:]]{3,30}\,\s?[[:alnum:]]{3,30}\,\s?[[:alnum:]]{3,30}\,\s?(male|female)$/
      game.CharCreate(sender, message.split(/\,\s?/)) unless game.check(sender)
    else
      game.descr['CharCreateError'] unless game.check(sender)
    end
  end

  bot.add_command(
      :type => type,
      :syntax => 'myrealemail [<адрес электронной почты>]',
      :description => 'показывает/задает адрес вашей электронной почты для отсылки на нее смс из игры(можно прописать почотвый адрес соответствующий вашему мобильному телефону типа: 79XXXXXXXXX@sms.beemail.ru, достаточно просто включить бесплатную услугу mail2sms у своего сотового провайдера и прописать тут свой смс ящик вместо адреса электронной почты)',
      :regex => /^myrealemail(\s+.{1,60})?$/i,
      :is_public => true
  ) do |sender, message|
    game.playeremail(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'mydescr <текст>',
      :description => 'ваше описание(внешность)',
      :regex => /^mydescr\s?.{0,1278}$/i,
      :is_public => true
  ) do |sender, message|
    game.SetMyDescr(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'info инфо',
      :description => 'Информация о вашем персонаже',
      :regex => /^(info)|(инфо)$/i,
      :is_public => true
  ) do |sender, message|
    game.playerinfo(sender) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'telnetpwd мойновыйпароль',
      :description => 'Установить пароль для входа через telnet (6-18 символов)',
      :regex => /^telnetpwd\s(.{6,18})?$/,
      :is_public => true
  ) do |sender, message|
    game.telnetpwd(sender, message) if game.check(sender)
  end

end
