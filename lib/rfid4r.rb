require 'event_handler/rfid_server'

# 
# La clase Rfid4r implementa directamente el servidor RFID de la clase 
# RfidServer.
#
class Rfid4r
  # Referencia al servidor RFID
  attr_reader :server

  # Instancia e inicia automaticamente los servicios del servidor RFID.
  # Un ejemplo sencillo de uso de esta clase se muestra a continuacion:
  #   
  #   require 'rubygems'
  #   require 'rfid4r'
  #   r = Rfid4r.new
  #   r.init
  #  se obtiene:
  #   [2008-10-03 12:34:48] INFO  WEBrick 1.3.1
  #   [2008-10-03 12:34:48] INFO  ruby 1.8.6 (2008-08-08) [i686-linux]
  #   [2008-10-03 12:34:48] INFO  RfidServer#start: pid=6394 port=8004
  def init	
   @server = RfidServer.new()
   trap("INT"){ @server.shutdown }
   @server.start
  end

  def stop
    @server.shutdown
  end
end

