# -*- coding: utf-8 -*-
def LoadAdmCmd(bot, game, type)

  bot.add_command(
      :type => type,
      :syntax => 'призвать <имя>',
      :description => 'призвать игрока',
      :regex => /^призвать\s#{USER_NAME_REGEX}$/i,
      :is_public => true
  ) do |sender, message|
    game.CallPlayer(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'recall',
      :description => game.descr['cmdrecall'],
      :regex => /^recall\s+[0-9]{1,4}$/i,
      :is_public => true
  ) do |sender, message|
    game.recall(sender, message.to_i) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'pinfo <name>',
      :description => 'player info',
      :regex => /^[Pp]info\s+#{USER_NAME_REGEX}$/i,
      :is_public => false
  ) do |sender, message|
    game.getplayerinfo(message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'paddr <name>',
      :description => 'get player address',
      :regex => /^[Pp]addr\s+#{USER_NAME_REGEX}$/i,
      :is_public => false
  ) do |sender, message|
    game.getplayeraddress(message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'ocode <номер в инвентаре>',
      :description => 'показывает/задает код объекта',
      :regex => /^[Oo]code\s[0-9]{1,3}\s?.*$/m,
      :is_public => false
  ) do |sender, message|
    game.objectcode(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'ocreate <тип> <Кточто[,Когочего,Комучему,Когочто,Кемчем,(0)ком(о)чём]>',
      :description => 'создать объект',
      :regex => /^ocreate\s[a-zA-Z0-9]{2,18}\s.{3,225}$/i,
      :is_public => false
  ) do |sender, message|
    game.ObjectCreate(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'addnpc <Кточто[,Когочего,Комучему,Когочто,Кемчем,(0)ком(о)чём]>',
      :description => 'Cоздать NPC
К примеру: "addnpc Дворник,Дворника,Дворнику,Дворника,Дворником,Дворнике" поставит дворника в локации, где вы находитесь.
Локация обязательно должна принадлежать вам.',
      :regex => /^addnpc\s.{3,225}$/i,
      :is_public => true
  ) do |sender, message|
    game.addnpc(sender, message) if game.check(sender)
  end


  bot.add_command(
      :type => type,
      :syntax => 'odel <номер>',
      :description => 'удалить объект',
      :regex => /^[Oo]del\s[0-9]{1,3}$/i,
      :is_public => false
  ) do |sender, message|
    game.ObjectDelete(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'setodescrs <номер> <описания>',
      :description => 'задать описания (действий) обьекту (например ключу): "setodescrs 1 ты достаешь ключ и открываешь им дверь ~gde~)><(~kto~ достал[а] ключ и открыл[а] дверь ~gde~)><(послышался звук отперающегося замка и дверь ~gde~ открылась)><(ты закрываешь дверь ~gde~ ключом)><(~kto~ закрыл[а] дверь ~gde~ на ключ)><(кто-то запер дверь ~gde~ с другой стороны"',
      :regex => /^setodescrs [0-9]{1,3}\s.+$/i,
      :is_public => true
  ) do |sender, message|
    game.SetObjDescrs(sender, message, "actions") if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'setobjdescr <номер> <описание>',
      :description => 'задать внешнее описание обьекту для просмотра в инвентаре (например ключу): "setobjdescr 1 Здоровый ключ со старинной гравировкой."',
      :regex => /^setobjdescr [0-9]{1,3}\s.+$/i,
      :is_public => true
  ) do |sender, message|
    game.SetObjDescrs(sender, message, "descr") if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'setobjadj <номер> <описание>',
      :description => 'задать прилагательные описание обьекту в описании локции (например ключу): "setobjadj 1 Большой  ключ лежит здесь, видимо его кто-то обронил."',
      :regex => /^setobjadj [0-9]{1,3}\s.+$/i,
      :is_public => true
  ) do |sender, message|
    game.SetObjDescrs(sender, message, "adj") if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'setkeydescrs <номер> <описания>',
      :description => 'задать описания ключу: "setkeydescrs 1 ты достаешь ключ и открываешь им дверь ~gde~)><(~kto~ достал[а] ключ и открыл[а] дверь ~gde~)><(послышался звук отперающегося замка и дверь ~gde~ открылась)><(ты закрываешь дверь ~gde~ ключом)><(~kto~ закрыл[а] дверь ~gde~ на ключ)><(кто-то запер дверь ~gde~ с другой стороны"',
      :regex => /^setkeydescrs [0-9]{1,3}\s.+$/i,
      :is_public => true
  ) do |sender, message|
    game.SetKeyDescr(sender, message) if game.check(sender)
  end

# FIXME: переделать время на системный таймер
  bot.add_command(
      :type => type,
      :syntax => 'gametime',
      :description => 'время в секундах после последнего рестарта сервера',
      :regex => /^gametime$/i,
      :is_public => false
  ) do |sender, message|
    game.time.to_s if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'ldelbyid <location id>',
      :description => game.descr['cmdldelbyid'],
      :regex => /^ldelbyid\s[0-9]{1,4}$/i,
      :is_public => false
  ) do |sender, message|
    game.dellocationbyid(sender, message.to_i) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'plist',
      :description => game.descr['cmdplist'],
      :regex => /^plist$/i,
      :is_public => false
  ) do |sender, message|
    if game.check(sender)
      game.playerslist()
    end
  end

  bot.add_command(
      :type => type,
      :syntax => 'pedit <string>',
      :description => game.descr['cmdpedit'],
      :regex => /^pedit\s[A-Za-z_\.0-9]{1,30}@[a-zA-Z0-9\.]{2,40}\.[a-z]{2,4}\s.+$/i,
      :is_public => false
  ) do |sender, message|
    if game.check(sender)
      #game.playeredit(sender,message)
    end
  end

  bot.add_command(
      :type => type,
      :syntax => 'pdel <address>',
      :description => game.descr['cmdpdel'],
      :regex => /^pdel\s.+$/i,
      :is_public => false
  ) do |sender, message|
    if game.check(sender)
      game.playerdelete(message)
    end
  end
  bot.add_command(
      :type => type,
      :syntax => 'shutdown <string>',
      :description => game.descr['cmdshutdown'],
      :regex => /^shutdown$/i,
      :is_public => false
  ) do |sender, message|
    game.SaveGame()
    bot.jabber.disconnect
    exit
  end

  bot.add_command(
      :type => type,
      :syntax => 'reboot',
      :description => 'горячая перезагрузка без сохранения',
      :regex => /^reboot$/i,
      :is_public => false
  ) do |sender, message|
    bot.jabber.disconnect
    exit
  end

  bot.add_command(
      :type => type,
      :syntax => 'dbshow <sql>',
      :description => game.descr['cmddbshow'],
      :regex => /^dbshow .+;$/i,
      :is_public => false
  ) do |sender, message|
    game.dbshow(message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'dlist',
      :description => game.descr['cmddlist'],
      :regex => /^dlist$/i,
      :is_public => false
  ) do |sender, message|
    game.descr.list if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'dedit <string>',
      :description => game.descr['cmddedit'],
      :regex => /^dedit\s[a-zA-Z0-9]{1,50}\s?.+$/m,
      :is_public => false
  ) do |sender, message|
    game.descr.edit(message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'ddel <string>',
      :description => game.descr['cmdddel'],
      :regex => /^ddel\s+.+$/i,
      :is_public => false
  ) do |sender, message|
    game.descr.delete(message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'giverights <address>',
      :description => game.descr['cmdgiverights'],
      :regex => /^giverights\s[A-Za-z_\.0-9]{1,30}@[a-zA-Z0-9\.]{2,40}\.[a-z]{2,4}$/i,
      :is_public => false
  ) do |sender, message|
    game.giveadminrights(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'takerights <address>',
      :description => game.descr['cmdtakerights'],
      :regex => /^takerights\s[A-Za-z_\.0-9]{1,30}@[a-zA-Z0-9\.]{2,40}\.[a-z]{2,4}$/i,
      :is_public => false
  ) do |sender, message|
    game.takeadminrights(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'reconnect',
      :description => game.descr['cmdreconnect'],
      :regex => /^reconnect$/i,
      :is_public => false
  ) do |sender, message|
#      bot.jabber.disconnect
#      sleep 3
    bot.jabber.reconnect
    "ok"
  end

  bot.add_command(
      :type => type,
      :syntax => 'save',
      :description => game.descr['cmdsave'],
      :regex => /^save$/i,
      :is_public => false
  ) do |sender, message|
    game.SaveGame() if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'last',
      :description => 'последние 10 посетителей',
      :regex => /^last$/i,
      :is_public => false
  ) do |sender, message|
    game.Last()
  end

  bot.add_command(
      :type => type,
      :syntax => 'upgrade',
      :description => 'выполняет код обновления',
      :regex => /^upgrade$/i,
      :is_public => false
  ) do |sender, message|
    game.upgrade()
  end

  bot.add_command(
      :type => type,
      :syntax => 'psavexml <имя игрока>',
      :description => 'Сохраняет все локации игрока в файлы',
      :regex => /^psavexml\s+#{USER_NAME_REGEX}$/i,
      :is_public => false
  ) do |sender, message|
    game.psavexml(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'news <текст>',
      :description => 'послать смс всем игрокам(например рассылка новостей)',
      :regex => /^news\s.+$/im,
      :is_public => false
  ) do |sender, message|
    game.sms2all(sender, message) if game.check(sender)
  end

  bot.add_command(
      :type => type,
      :syntax => 'revision',
      :regex => /^revision$/i,
      :is_public => true
  ) do |sender, message|
    "REVISION: #{`git log --pretty=format:'%h - %ar(%ad): %s' -n 1`}"
  end
end
