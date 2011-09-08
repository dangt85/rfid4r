require 'webrick'
require 'rubygems'
require 'sqlite3'
require 'readers_adapter/phidget_rfid_reader'
require 'inteface_aplication/rfid_interface_client'

#
# La clase RfidServer representa el manejador de eventos del Middleware RFID, 
# para el manejo de los eventos generados por las capturas de etiquetas RFID.
# RfidServer es una clase concreta de la clase WEBrick::GenericServer que 
# implementa un servidor para el manejo de un lector RFID. Adicionalmente 
# recibe comandos que permiten consultar, registrar y liberar el lector RFID, 
# asi como tambien comandos para consultar la base de datos SQLite de eventos 
# RFID.
#
class RfidServer < WEBrick::GenericServer
  # Representa una referencia a una interfaz cliente para consultas hacia otros 
  # servidores RFID
  attr_reader :interface_client
  # Referencia al lector RFID conectado al servidor 
  attr_reader :reader
  # Referencia logica para la presencia o no del lector RFID
  attr_reader :is_attach
  # Referencia logica para la activacion o no del muestreo de eventos RFID
  attr_reader :active
  # Referencia logica para la activacion o no del muestreo de eventos RFID remoto
  attr_reader :active_remote
  # Referencia al tiempo de espera para conectar el lector RFID
  attr_reader :timeout
  # Representa una referencia al monitor de enventos le lectura de tags RFID
  attr_reader :verbose
  # Representa una referencia al monitor de enventos le lectura de tags RFID remoto
  attr_reader :verbose_remote
  # Referencia a un semaforo de sincronizacion de captura de eventos RFID
  attr_reader :mutex
  
  #
  # Crea un nuevo servidor RFID utilizando el archivo de configuracion 
  # "rfid_config.yml", adicionalmente instancia la base de datos SQLite de 
  # eventos para su uso porterior.
  #
  def initialize(config={}, default=WEBrick::Config::General)
    @interface_client =     RfidInterfaceClient.new
    p =                     @interface_client.config["local_config"]["port"]
    ip =                    @interface_client.config["local_config"]["ip_address"]
    @timeout =              @interface_client.config["local_config"]["timeout"]
    config[:Port] =         p unless p.nil?
    config[:BindAddress] =  ip unless ip.nil?
    @is_attach =            false
    @active =               false
    @active_remote =        false
    @mutex =                Mutex.new
    super
    @db =                   SQLite3::Database.new('rfid_events.db')
  end
  
  #
  # Recibe y procesa los comandos, a continuacion se muestra una lista de los comandos soportados 
  # y una breve descripcion de su funcion:
  #
  #   attach:       		Attach a new RFID reader
  #   detach:       		Detach the RFID reader
  #   ls|list|reader:   	Serial of RFID reader
  #   n|name:       		Name of RFID reader 
  #   t|type:       		Type of RFID reader
  #   version:       		Version of RFID reader
  #   verbose:   		Initialize the observer of RFID events 
  #   stop:	   		Stop the observer of RFID events
  #   server:       		List all servers 
  #   set [id_of_server]:	Change the current server
  #   current:   		Show the current server selected
  #   select [SQL]:     	Consulta de tipo SQL a la base de datos SQLite
  #   quit|close|exit:  	Close the connection with de server
  #
  def run(sock)
    while true
      cmd = sock.gets
      case cmd
        when /\bclose|exit|quit\W/
        sock.print "Shutting down..."
        break
        # ************************* servers ******************************
        when /\bservers\W/
        if @interface_client.servers>0
          @interface_client.config.each do |key, value| 
            sock.print "Server: #{key} #{value["ip_address"]}:#{value["port"]}, Id of server: #{value["id_server"]}\n"
          end
        else
          sock.print "ERROR: No Server Found!\n"
        end
        # ************************* current server ******************************
        when /\bcurrent\W/
        server_name = @interface_client.id_server
        sock.print "Server: #{server_name} #{@interface_client.config[server_name]["ip_address"]}:#{@interface_client.config[server_name]["port"]} , Id of server: #{@interface_client.config[server_name]["id_server"]}\n"
        # ************************* set server ******************************
        when /\bset\s+([0-9A-Za-z])+/
        if @interface_client.servers>0
          @interface_client.set_server(sock,cmd.split(/\s/)[1])
        else
          sock.print "ERROR: No Server Found!\n"
        end
        # ************************* attach **********************************
        when /\battach\W(\s*-r)?/
        if @interface_client.id_server.eql?("local_config")
          if !@is_attach
            begin
              @reader = PhidgetRfidReader.new(@timeout)
              @is_attach = true
              sock.print "Device #{@reader.serial} found!\n"
            rescue Exception => e
              sock.print "ERROR: #{e}\n"
            end
          else
            sock.print "ERROR: An RFID reader is attached!\n"
          end
        elsif @interface_client.servers>0
          @interface_client.single_consult(sock,"attach -r\n")
        end
        if cmd.split(/\s/)[1].eql?("-r")
          break
        end
        # ************************* ls|list|reader **********************************
        when /\bls|list|reader\W(\s*-r)?/
        if @interface_client.id_server.eql?("local_config")
          if @is_attach
            sock.print "#{@reader.serial}\n"
          else
            sock.print "ERROR: No device found!\n"
          end
        elsif @interface_client.servers>0
          @interface_client.single_consult(sock,"ls -r\n")
        end
        if cmd.split(/\s/)[1].eql?("-r")
          break
        end
        # ************************* name **********************************
        when /\bn|name\W(\s*-r)?/
        if @interface_client.id_server.eql?("local_config")
          if @is_attach
            sock.print "#{@reader.name}\n"
          else
            sock.print "ERROR: No device found!\n"
          end
        elsif @interface_client.servers>0
          @interface_client.single_consult(sock,"n -r\n")
        end
        if cmd.split(/\s/)[1].eql?("-r")
          break
        end
        # ************************* type **********************************
        when /\bt|type\W(\s*-r)?/
        if @interface_client.id_server.eql?("local_config")
          if @is_attach
            sock.print "#{@reader.type}\n"
          else
            sock.print "ERROR: No device found!\n"
          end
        elsif @interface_client.servers>0
          @interface_client.single_consult(sock,"t -r\n")
        end
        if cmd.split(/\s/)[1].eql?("-r")
          break
        end
        # ************************* version **********************************
        when /\bversion\W(\s*-r)?/
        if @interface_client.id_server.eql?("local_config")
          if @is_attach
            sock.print "#{@reader.version}\n"
          else
            sock.print "ERROR: No device found!\n"
          end
        elsif @interface_client.servers>0
          @interface_client.single_consult(sock,"version -r\n")
        end
        if cmd.split(/\s/)[1].eql?("-r")
          break
        end
        # ************************* detach **********************************
        when /\bdetach\W(\s*-r)?/
        if @interface_client.id_server.eql?("local_config")
          if @is_attach
            @reader.delete
            @is_attach = false
            if @active
              @verbose.exit
              @active = false
            end
            sock.print "Device #{@reader.serial} detached!\n"
          else
            sock.print "ERROR: No device found!\n"
          end
        elsif @interface_client.servers>0
          @interface_client.single_consult(sock,"detach -r\n")
        end
        if cmd.split(/\s/)[1].eql?("-r")
          break
        end
        # ************************* detachall **********************************
        # when /\bdetachall\W/
        # @readers.each do |s,r|
        #   sock.print "Device #{r.serial} detached!\n"
        #   r.delete
        # end
        # @readers.clear
        # ************************* consult **********************************
        when /\bconsult/
        @db.execute(cmd.split("consult")[1]) do |row|
          row.each do |col|
            sock.print "#{col.to_s};"
          end
          sock.print "\n"
        end
        break
        # ************************* select SQL **********************************
        when /\bselect/
        begin
          if @interface_client.id_server.eql?("local_config")
            @db.execute(cmd) do |row|
              row.each do |col|
                sock.print "#{col.to_s};"
              end
              sock.print "\n"
            end
          elsif @interface_client.servers>0
            @interface_client.consult(sock,"consult #{cmd}")
          end
        rescue SQLite3::SQLException => e
          sock.print "ERROR: #{e}\n"
        rescue Exception => e
          sock.print "ERROR: #{e}\n"
        end
        # ******************** Mostrar eventos a cierta frecuencia ************************
        when /\bverbose\W(\s*-r)?/
        if @interface_client.id_server.eql?("local_config")
          if !@active and @is_attach
            @active = true
            tag = 0
            opt = cmd.split(' ')[1]
            @verbose = Thread.new(opt) do
              while true
                if @reader.count > tag
                  tag = @reader.count
                  sock.print "Reader:#{@reader.serial} #{@reader.lastTag()}\n" 
                elsif !@active
                  sock.print "MESSAGE: Stop Verbose\n"
                  break
                else
                  sock.print " "
                end
                sleep(0.1)
              end
            end
          end
        elsif @interface_client.servers>0
          if !@active_remote
            @active_remote = true
            @verbose_remote = Thread.new do
              @interface_client.consult(sock,"verbose -r -r")
            end
          end
        end
        # ************************* Parar Muestreo **********************************
        when /\bstop\W(\s*-r)?/
        if @interface_client.id_server.eql?("local_config")
          if @active
            #sock.print "MESSAGE: Stop Verbose\n"
            @active = false
            #@verbose.exit
          end
        elsif @interface_client.servers>0
          if @active_remote
            @interface_client.single_consult(sock,"stop -r\n")
            #@verbose_remote.exit
            @active_remote = false
          end
        end
        if cmd.split(/\s/)[1].eql?("-r")
          break
        end
        # ************************* h|help **********************************
        when /\bh|help\W/
        sock.print "attach:             Attach a new RFID reader\n"
        sock.print "detach:             Detach the RFID reader\n"
        sock.print "ls|list|reader:     Serial of RFID reade\n"
        sock.print "n|name:             Name of RFID reader\n"
        sock.print "t|type:             Type of RFID reader\n"
        sock.print "version:            Version of RFID reader\n"
        sock.print "verbose:            Initialize the observer of RFID events\n"
        sock.print "stop:               Stop the observer of RFID events\n"
        sock.print "server:             List all servers\n"
        sock.print "set [id_of_server]: Change the current server\n"
        sock.print "current:            Show the current server selected\n"
        sock.print "select [SQL]:       Consulta de tipo SQL a la base de datos SQLite\n"
        sock.print "quit|close|exit:    Close the connection with de server\n"
      else
        sock.print "ERROR: Unknown command! Type h or help for Help\n"
      end
    end
  end
end
