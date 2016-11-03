# -*- coding: utf-8 -*-
require 'socket'
require 'iconv'
require_relative 'registration'

class String
  def black;
    "\033[30m#{self}\033[0m"
  end

  def red;
    "\033[31m#{self}\033[0m"
  end

  def green;
    "\033[32m#{self}\033[0m"
  end

  def brown;
    "\033[33m#{self}\033[0m"
  end

  def blue;
    "\033[34m#{self}\033[0m"
  end

  def magenta;
    "\033[35m#{self}\033[0m"
  end

  def cyan;
    "\033[36m#{self}\033[0m"
  end

  def gray;
    "\033[37m#{self}\033[0m"
  end

  def bg_black;
    "\033[40m#{self}\0330m"
  end

  def bg_red;
    "\033[41m#{self}\033[0m"
  end

  def bg_green;
    "\033[42m#{self}\033[0m"
  end

  def bg_brown;
    "\033[43m#{self}\033[0m"
  end

  def bg_blue;
    "\033[44m#{self}\033[0m"
  end

  def bg_magenta;
    "\033[45m#{self}\033[0m"
  end

  def bg_cyan;
    "\033[46m#{self}\033[0m"
  end

  def bg_gray;
    "\033[47m#{self}\033[0m"
  end

  def bold;
    "\033[1m#{self}\033[22m"
  end

  def reverse_color;
    "\033[7m#{self}\033[27m"
  end

  def pure_string
    loop { self[/\033\[\d+m/] = "" }
  rescue IndexError
    return self
  end
end
class TelnetUser
  attr_accessor :sock, :enc

  def initialize(s, e)
    @sock = s
    @enc = e
  end
end

class TelServ
  attr_accessor :jb

#    TIOCGWINSZ =  0x40087468
  Encodings = ["KOI8-R", "UTF-8", "WINDOWS-1251", "cp866"]

  def initialize(jb, port=34567, host='0.0.0.0', maxcon=18)
    @logins = {}
    #@encoding = Encodings[1]
    #server = TCPServer.new(host, port)
    @jb = jb
    telnet_thread = Thread.new do
      Socket.tcp_server_loop(host,port) {|client, client_addrinfo|
        Thread.new {
          begin
            log("#{client_addrinfo.ip_address} is connected")
            serv(client)
            @logins.delete(client)
            client.close
            log("#{client_addrinfo.ip_address} is disconnected")
          ensure
            client.close
          end
        }
      }

      # loop do
      #   Thread.start(server.accept) do |client|
      #     log("#{client.peeraddr[2]}:#{client.peeraddr[1]} is connected")
      #     serv(client)
      #     client.close
      #     @logins.delete(client)
      #   end
      # end
    end
  end

  def setcolors(t)
    return nil if t==false
    t=t.gsub("<ч>", "\033[30m")
    t=t.gsub("<к>", "\033[31m")
    t=t.gsub("<з>", "\033[32m")
    t=t.gsub("<кор>", "\033[33m")
    t=t.gsub("<с>", "\033[34m")
    t=t.gsub("<п>", "\033[35m")
    t=t.gsub("<г>", "\033[36m")
    t=t.gsub("<g>", "\033[37m")
    t=t.gsub("<Ч>", "\033[40m")
    t=t.gsub("<К>", "\033[41m")
    t=t.gsub("<З>", "\033[42m")
    t=t.gsub("<КОР>", "\033[43m")
    t=t.gsub("<С>", "\033[44m")
    t=t.gsub("<П>", "\033[45m")
    t=t.gsub("<Г>", "\033[46m")
    t=t.gsub("<G>", "\033[47m")
    t.gsub(/<\/[кзсжчпгg]{1}>/i, "\033[0m")
  end

  def q(qu, s, e)
    s.write denc(qu, e)
    a = sock.gets
    a.chomp! unless a.nil?
    a
  end

  def serv(sock)
    logged_in = false
    encoding_selected = false
    sock.write "
 *  .   '   *      #   .    .    *     '  ,\r\n".cyan()+
                   ".    *     .   *   .     .   '    `    *\r\n".cyan()+
                   " . ".cyan()+"-=<(".blue()+"Forgotten dreaM".bold()+")>=- ".blue()+"'  *\r\n".cyan()+
                   "  *      .    *    .    *     .    '   .\r\n".cyan()+
                   "*    .     '      *      .    `    *     '\r\n".cyan()

    login = ""
    password = ""

    begin
      loop do
        until encoding_selected
          sock.write "\r\nSelect encoding: "
          i = 1
          Encodings.each { |e|
            sock.write "#{i} - #{e}"+((Encodings.size > i) ? ", " : "")
            i += 1
          }
          sock.write ": "
          ei = sock.gets.to_i
          next if ei > Encodings.size or ei <= 0
          encoding = Encodings[ei-1]
          encoding_selected = true
        end
        until logged_in
          sock.write("\r\n"+ denc('Введите ваш jabber id или логин для входа', encoding)+"\r\n")
          sock.write(denc('Не зарегестрированны? Введите new для регистрации', encoding)+"\r\n")

          login = sock.gets
          login.chomp! unless login.nil?
          login = enc(login, encoding)
          if (login=='new')
            type = 'telnet'
            reg = Registration.new(type, $gg)

            sock.write("\r\n"+denc('Для входа необходимо пройти небольшую процедуру регистрации.', encoding)+"\r\n")

            temp_id = 'telnetID'
            question = ''
            answer = ''
            loop_id = 0
            loop {
              question = denc(reg.RegPlayerWithLoginAndPassword(temp_id, answer),encoding)
              if question == reg.registration_aborted_message
                sock.write question
                break
              end

              sock.write(question + ': ')

              if question == reg.registred_message
                sock.write(question)
                break
              end

              answer = sock.gets.chomp!
              answer = enc(answer,encoding)

              login = answer if question == reg.questions_with_login_password_messages[0]
              password = answer if question == reg.questions_with_login_password_messages[1]
            }
          else
            sock.write denc("\nПароль: ", encoding)
            sock.write colorize(0, "", "fg")
            sock.write colorize(0, "", "bg")
            password = sock.gets.chomp
            password = enc(password, encoding)
          end

          sock.write nocolor ""
          login = login+'@telnet' if $gg.players.key?(login+'@telnet')
          if $gg.players.key?(login) && $gg.players[login].pwd == Digest::MD5.hexdigest(password) 
            logged_in = true
            @logins[login] = TelnetUser.new(sock, encoding)
            if $gg.players[login].ready
              parse_command(login, "l")
            else
              parse_command(login, "start")
            end
          else
            # bruteforce protection :D
            sleep 3
          end
        end

        message = sock.gets
        break if message.nil?
        message.chomp!

        if enc(message, @logins[login].enc) =~ /^((stop)|(стоп))$/i
          sock.puts $gg.stop(login)
          sleep 1
          break
        end
        parse_command(login, message)
      end
    rescue => detail
      log "Ошибка в главном обработчике telnet: #{$!.to_s}"+detail.backtrace.join("\n")
      fclose(login)
    end
  end

  def deliver(login, message)
    begin
      return false if @logins.nil?
      return false unless @logins.key? login
      return true if @logins[login].sock.closed?
      message = message.gsub("\n", " \n\r ")
      message = setcolors(message)
      mes = denc(message, @logins[login].enc)
      @logins[login].sock.write mes+" \n\r"
      true
    rescue => detail
      log "Ошибка в telnet при выводе сообщения: #{$!.to_s}"+detail.backtrace.join("\n")
      fclose(login)
    end
  end

  def fclose(login)
    return false if @logins.nil?
    return false unless @logins.key? login
    begin
      $gg.stop(login)
      @logins[login].sock.close unless @logins[login].sock.closed?
      @logins.delete(login)
    rescue => detail
      log "Ошибка принудительного закрытия сокета telnet: #{$!.to_s}"
      log detail.backtrace.join("\n")
    end
  end

  def log(mes)
    $stderr.puts "\n[#{Time.now.to_s}]: "+mes
  end

  def enc(s, encoding)
    s = s.force_encoding(encoding)
    s = s.scan(/[[:print:]]/).join if encoding == 'UTF-8'
    Iconv.iconv('UTF-8', encoding+'//IGNORE', s)[0]
  end

  def denc(s, encoding)
    s = s.force_encoding(encoding)
    Iconv.iconv(encoding+'//IGNORE', 'UTF-8', s)[0]
  end

  def parse_command(sender, message)
    #parse_thread = Thread.new do
    return if message.nil?
    return if sender.nil?
    return unless @logins.key? sender
    begin
      cmd = enc(message, @logins[sender].enc)
      cmd = CGI::unescapeHTML(cmd)
      @jb.parse_command(sender, cmd)
    rescue => detail
      log "\nОшибка telnet при отправке команды боту: #{$!.to_s}\n"+detail.backtrace.join("\n")
    end
    #end
    #parse_thread.join
  end

  ColorMode = {'fg' => '38', 'bg' => '48'}

  def colorize(color, text, mode)
    "\x1b[#{ColorMode[mode]};5;#{color}m#{text}"
  end

  def nocolor(text)
    "\x1b[0m#{text}"
  end

end
