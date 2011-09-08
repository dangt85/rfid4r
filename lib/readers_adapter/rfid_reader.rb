# 
# La clase RfidReader encapsula la estructura básica de los metodos de un 
# lector RFID. Las subclases deberan redefinir los metodos sin cambiar su 
# estructura.
#
class RfidReader
  # Referencia al nombre del lector RFID
  attr_accessor :name
  # Referencia al tipo de lector RFID
  attr_accessor :type
  # Referencia al serial unico del lector RFID
  attr_accessor :serial
  # Referencia a la versión del lector RFID
  attr_accessor :version
  
  #
  # Crea un nuevo lector RFID con sus atributos básicos. 
  #
  def initialize(name, type, serial, version)
    @name=name
    @type=type
    @serial=serial
    @version=version
  end

  #
  # Muestra las propiedas básicas del lector RFID, como nombre, tipo, serial 
  # y/o versión.
  #
  def properties
  end
  
  #
  # Elimina el lector RFID, con lo cual se dejara de detectar las etiquetas 
  # RFID.
  #
  def delete
  end

end
