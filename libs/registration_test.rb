# Author: Vladislav Fursov (ghostrussian@gmail.com)
require_relative 'registration'
require_relative 'game-mock.rb'
require 'test/unit'

class RegistrationTest < Test::Unit::TestCase
  def setup
    @type = 'test'
    @game = prepareGame()
    @reg = Registration.new(@type, @game)
    @id = 'tester'
  end

  def teardown
    ## Nothing really
  end

  def test_reg_player
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id, ''), '1 question')
    assert_equal(@reg.questions_messages[1], @reg.RegPlayer(@id, 'Вася'), '2 question')
    assert_equal(@reg.questions_messages[2], @reg.RegPlayer(@id, 'Васю'), '3 question')
    assert_equal(@reg.questions_messages[3], @reg.RegPlayer(@id, 'Васе'), '4 question')
    assert_equal(@reg.questions_messages[4], @reg.RegPlayer(@id, 'Васей'), '5 question')
    assert_equal(@reg.questions_messages[5], @reg.RegPlayer(@id, 'Васе'), '6 question')
    assert_equal(@reg.questions_messages[6], @reg.RegPlayer(@id, 'Васи'), '7 question')
    assert_equal(@reg.registred_message, @reg.RegPlayer(@id, 'male'), '8 question')

    assert_equal(true, @game.players.key?(@reg.GetLogin(@id)))

    assert_equal('Вася', @game.players[@reg.GetLogin(@id)].name)
    assert_equal('Васю', @game.players[@reg.GetLogin(@id)].kogo)
    assert_equal('Васе', @game.players[@reg.GetLogin(@id)].komu)
    assert_equal('Васей', @game.players[@reg.GetLogin(@id)].kem)
    assert_equal('Васе', @game.players[@reg.GetLogin(@id)].okom)
    assert_equal('Васи', @game.players[@reg.GetLogin(@id)].chey)
    assert_equal('male', @game.players[@reg.GetLogin(@id)].sex)
    assert_equal(@reg.GetLogin(@id), @game.players[@reg.GetLogin(@id)].addr)
    assert_equal(nil, @game.players[@reg.GetLogin(@id)].pwd)
  end

  def test_reg_player_sex_check
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id, ''), '1 question')
    assert_equal(@reg.questions_messages[1], @reg.RegPlayer(@id, 'Вася'), '2 question')
    assert_equal(@reg.questions_messages[2], @reg.RegPlayer(@id, 'Васю'), '3 question')
    assert_equal(@reg.questions_messages[3], @reg.RegPlayer(@id, 'Васе'), '4 question')
    assert_equal(@reg.questions_messages[4], @reg.RegPlayer(@id, 'Васей'), '5 question')
    assert_equal(@reg.questions_messages[5], @reg.RegPlayer(@id, 'Васе'), '6 question')
    assert_equal(@reg.questions_messages[6], @reg.RegPlayer(@id, 'Васи'), '7 question')
    assert_equal(@reg.questions_messages[6], @reg.RegPlayer(@id, 'test'), '8 question')
    assert_equal(@reg.questions_messages[6], @reg.RegPlayer(@id, 'qwert'), '9 question')
    assert_equal(@reg.registred_message, @reg.RegPlayer(@id, 'male'), '10 question')

    assert_equal(true, @game.players.key?(@reg.GetLogin(@id)))
  end

  def test_reg_player_if_answer_empty
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id, ''), '1 question')
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id, ''), '2 question')
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id, ''), '3 question')
  end

  def test_reg_player_if_answer_empty_center
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id, ''), '1 question')
    assert_equal(@reg.questions_messages[1], @reg.RegPlayer(@id, 'Вася'), '2 question')
    assert_equal(@reg.questions_messages[2], @reg.RegPlayer(@id, 'Васю'), '3 question')
    assert_equal(@reg.questions_messages[3], @reg.RegPlayer(@id, 'Васе'), '4 question')
    assert_equal(@reg.questions_messages[3], @reg.RegPlayer(@id, ''), '5 question')
    assert_equal(@reg.questions_messages[3], @reg.RegPlayer(@id, ''), '6 question')
    assert_equal(@reg.questions_messages[4], @reg.RegPlayer(@id, 'Васей'), '6 question')
  end

  def test_reg_player_paralell
    @id1 = 'Slaytor'
    @id2 = 'Ghost_Russia'
    @id3 = 'qwerty'

    # user 1
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id1, ''), "1 question for #{@id1}")
    assert_equal(@reg.questions_messages[1], @reg.RegPlayer(@id1, 'Вася'), "2 question for #{@id1}")

    # user 2
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id2, ''), "1 question for #{@id2}")
    assert_equal(@reg.questions_messages[1], @reg.RegPlayer(@id2, 'Вася'), "2 question for #{@id2}")

    # user 3
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id3, ''), "1 question for #{@id3}")
    assert_equal(@reg.questions_messages[1], @reg.RegPlayer(@id3, 'Вася'), "2 question for #{@id3}")

    # user 1
    assert_equal(@reg.questions_messages[2], @reg.RegPlayer(@id1, 'Васю'), "3 question  for #{@id1}")

    # user 2
    assert_equal(@reg.questions_messages[2], @reg.RegPlayer(@id2, 'Васю'), "3 question  for #{@id2}")

    # user 3
    assert_equal(@reg.questions_messages[2], @reg.RegPlayer(@id3, 'Васю'), "3 question  for #{@id3}")
  end

  def test_reset
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id, ''), '1 question')
    assert_equal(@reg.questions_messages[1], @reg.RegPlayer(@id, 'Вася'), '2 question')
    assert_equal(@reg.questions_messages[2], @reg.RegPlayer(@id, 'Васю'), '3 question')
    @reg.Reset(@id)
    assert_equal(@reg.questions_messages[0], @reg.RegPlayer(@id, ''), '1 question')
    assert_equal(@reg.questions_messages[1], @reg.RegPlayer(@id, 'Вася'), '2 question')
    assert_equal(@reg.questions_messages[2], @reg.RegPlayer(@id, 'Васю'), '3 question')
  end

  def test_reg_player_with_login_pass
    login = 'test@test.ru'
    assert_equal(@reg.questions_with_login_password_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, ''), 'login question')
    assert_equal(@reg.questions_with_login_password_messages[1], @reg.RegPlayerWithLoginAndPassword(@id, login), 'pass question')
    assert_equal(@reg.questions_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, '123456'), '1 question')
    assert_equal(@reg.questions_messages[1], @reg.RegPlayerWithLoginAndPassword(@id, 'Вася'), '2 question')
    assert_equal(@reg.questions_messages[2], @reg.RegPlayerWithLoginAndPassword(@id, 'Васю'), '3 question')
    assert_equal(@reg.questions_messages[3], @reg.RegPlayerWithLoginAndPassword(@id, 'Васе'), '4 question')
    assert_equal(@reg.questions_messages[4], @reg.RegPlayerWithLoginAndPassword(@id, 'Васей'), '5 question')
    assert_equal(@reg.questions_messages[5], @reg.RegPlayerWithLoginAndPassword(@id, 'Васе'), '6 question')
    assert_equal(@reg.questions_messages[6], @reg.RegPlayerWithLoginAndPassword(@id, 'Васи'), '7 question')
    assert_equal(@reg.registred_message, @reg.RegPlayerWithLoginAndPassword(@id, 'male'), '8 question')

    assert_equal(true, @game.players.key?(@reg.GetLogin(login)))

    assert_equal('Вася', @game.players[@reg.GetLogin(login)].name)
    assert_equal('Васю', @game.players[@reg.GetLogin(login)].kogo)
    assert_equal('Васе', @game.players[@reg.GetLogin(login)].komu)
    assert_equal('Васей', @game.players[@reg.GetLogin(login)].kem)
    assert_equal('Васе', @game.players[@reg.GetLogin(login)].okom)
    assert_equal('Васи', @game.players[@reg.GetLogin(login)].chey)
    assert_equal('male', @game.players[@reg.GetLogin(login)].sex)
    assert_equal(@reg.GetLogin(login), @game.players[@reg.GetLogin(login)].addr)
    assert_equal(Digest::MD5.hexdigest('123456'), @game.players[@reg.GetLogin(login)].pwd)

  end

  def test_reg_player_if_answer_empty_with_login_pass
    assert_equal(@reg.questions_with_login_password_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, ''), 'login 1 question')
    assert_equal(@reg.questions_with_login_password_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, ''), 'login 2 question')
    assert_equal(@reg.questions_with_login_password_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, ''), 'login 3 question')
  end

  def test_reset_with_login_pass
    assert_equal(@reg.questions_with_login_password_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, ''), 'login question')
    assert_equal(@reg.questions_with_login_password_messages[1], @reg.RegPlayerWithLoginAndPassword(@id, 'test@test.ru'), 'pass question')
    assert_equal(@reg.questions_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, '123456'), '1 question')
    @reg.Reset(@id)
    assert_equal(@reg.questions_with_login_password_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, ''), 'login question')
    assert_equal(@reg.questions_with_login_password_messages[1], @reg.RegPlayerWithLoginAndPassword(@id, 'test@test.ru'), 'pass question')
    assert_equal(@reg.questions_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, '123456'), '1 question')
  end

  def test_user_exist_with_login_pass
    login = "petya@#{@type}"

    assert_equal(@reg.questions_with_login_password_messages[0], @reg.RegPlayerWithLoginAndPassword(@id, ''), 'login question')
    assert_equal(@reg.questions_with_login_password_messages[1], @reg.RegPlayerWithLoginAndPassword(@id, login), 'pass question')
    assert_equal(@reg.user_exist_message, @reg.RegPlayerWithLoginAndPassword(@id, '123456'))
  end

  # prepare for test
  def prepareGame()
    game = Game.new

    # add player
    p = Player.new(
        "Петя", "Петю", "Пете",
        "Петей", "Пете", "Пети", "male",
        true, 1, "player", "Обычный игрок", "")
    p.id = 1
    p.knownlocs = []
    p.inventory = []
    p.sms = []
    p.sensibleness = 10
    p.lastlogin = 1234567
    p.createdate = 123456
    p.addr = "petya@#{@type}"

    game.players[p.addr] = p

    return game
  end
end