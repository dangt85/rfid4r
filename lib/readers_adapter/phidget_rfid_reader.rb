require 'phid'
require 'readers_adapter/rfid_reader'
require 'observer'

# 
# PhidgetRfidReader es una clase concreta de la clase RfidReader que define en 
# detalle la estructura de los metodos de un lector RFID.
#
class PhidgetRfidReader < RfidReader
  # El modulo Phid encapsula el wrapper de lector RFID PhidgetRFID-1023.
  include Phid
  
  #
  # Crea un nuevo lector RFID con sus atributos básicos. 
  # Adicionalmente maneja un log de registro de eventos de lecturas de 
  # etiquetas RFID, estos eventos son almacenados en una base de datos SQLite a 
  # la vez que son leidos por el lector RFID.
  #
  def initialize(timeout=10,log='phid.log', dbname='rfid_events.db')
    begin
      rfid_create(dbname)
      result = wait_attachment(timeout)
      if result != 0
        raise get_error_description(result)
      end
      super(get_device_name, get_device_type, get_serial_number, get_device_version)
      puts "Device #{name}::#{serial} Found!\n"
      log_message("#{self}", "Device #{name}::#{serial} Found!\n")
      enable_loggin("#{serial}-#{log}")
      turn_antenna_on
    rescue Exception => e
        puts "ERROR: #{e}"
        raise get_error_description(result)
    end
  end
  
  #
  # Activa o desactiva la antena del lector RFID.
  #
  def antenna(set)
    if set
      turn_antenna_on
    else
      turn_antenna_off
    end
  end
  
  #
  # Muestra por salida estandar las propiedas básicas del lector RFID, como 
  # nombre, tipo, serial y versión.
  #
  def properties
    puts "Device Name: #{name}\n"
    puts "Device Type: #{type}\n"
    puts "Device Serial: #{serial}\n"
    puts "Device Version: #{version}\n"
  end
  
  #
  # Elimina el lector RFID mostrando un aviso de notificacion, con lo cual se 
  # dejara de detectar las etiquetas RFID. Adicionalmente, este evento es 
  # almacenado en el log de registro y en la base de datos SQLite.
  #
  def delete
    puts "Device #{name}::#{serial} Dettached!\n"
    log_message("#{self}", "Device #{name}::#{serial} Dettached!\n")
    rfid_delete
  end
  
  #
  # Retorna el último ID leído por el lector.
  #
  def lastTag
    get_lastTag
  end
  
  #
  # Retorna el número de eventos de lectura registrados por el lector.
  #
  def count
    count_tags
  end
  
end
