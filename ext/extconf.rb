require 'mkmf'

$LIBS += " -lphidget21 -lsqlite3"

create_makefile('phid')

