require 'net/telnet'
require 'rubygems'
require 'yaml'

#
# La clase RfidInterfaceClient representa una interfaz para un cliente Telnet genérico
#
class RfidInterfaceClient 
  # Referencia a un hash de parámetros de configuración
  attr_reader :config
  # Referencia a cantidad de servidores instanciados
  attr_reader :servers
  # Representa el identificado del servidor actualmente en uso
  attr_reader :id_server
  
  #
  # Crea una nueva interfaz para un cliente Telnet genérico, a partir de los parámetros 
  # de configuración obtenidos desde el archivo "rfid_config.yml"
  #
  def initialize(yml='rfid_config.yml')
    parse =     YAML::parse(File.open(yml))
    @config =   parse.transform
    @id_server =  "local_config"
    @servers =  0
    @config.each do |key, value| 
      if key.include?("server")
        @servers = @servers + 1
      end
    end
  end
  
  #
  # Ejecuta un comando y recibe una o más respuestas, imprimiéndola(s) en el socket
  #
  def consult(sock,cmd)
    begin
      conection = Net::Telnet::new("Host" => @config[@id_server]["ip_address"].to_s,"Timeout" => 5,"Port" => @config[@id_server]["port"])
      sock.print "MESSAGE: Server "+@config[@id_server]["ip_address"].to_s+":"+@config[@id_server]["port"].to_s+"\n"
      conection.cmd("#{cmd.chop}") do |response|
        sock.print response.to_s
        if response.to_s.include?("Stop Verbose")
         conection.puts("exit")
        end
      end
    rescue Exception => e
      sock.print "ERROR: Couldn't establish the conexion!\n"
    end
  end
  
  #
  # Ejecuta un comando y recibe una respuesta, imprimiéndola en el socket
  #
  def single_consult(sock,cmd)
    begin
      conection = Net::Telnet::new("Host" => @config[@id_server]["ip_address"].to_s,"Timeout" => 5,"Port" => @config[@id_server]["port"])
      sock.print "MESSAGE: Server "+@config[@id_server]["ip_address"].to_s+":"+@config[@id_server]["port"].to_s+"\n"
      conection.puts("#{cmd.chop}") 
      sock.print conection.gets
      #conection.close
    rescue
      sock.print "ERROR: Couldn't establish the conexion!\n"
    end
  end

  #
  # Permite cambiar el servidor al cual seran dirigidos los comandos
  # y consultas
  #
  def set_server(sock, id)
     change = false
     @config.each do |key, value| 
          if value["id_server"].to_s.eql?(id)
           change = true    
           @id_server = key
	   sock.print "MESSAGE: Change to Server #{id} Complete!\n"
	   break
          end
      end
      if !change
        sock.print "ERROR: No Server Found!\n"
      end
  end
  
end
