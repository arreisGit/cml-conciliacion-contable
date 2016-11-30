# Poblemas conocidos para la herramienta de conciliacion contable.
## To do
1. Hay que revisar el escenario de las aplicaciones en la conciliacion
del IVA Por Acreditar. Un ejemplo del caso es la aplicacion MY1495,
donde existe una diferencia entre el tipo de cambio de las entradas
que se estan aplicando contra el de la nota de credito. Lo cual
presenta un escenario natural donde al parecer se necesita de una
fluctuacion que al dia de hoy no se esta realizando.

2. Cuandos se corre la herramienta de conciliacion contable, en el 
mes actual y para el IVA Por Acreditar truena con un error SQL de
que no puede insertar un valaor nulo a una de las tablas de la 
conciliacion.

## En Revision
1. Hay que asegurarse que en el proceso del mapeo entre auxiliares 
y conttabilidad regrese el concepto de cualquiese que sea 
el origen encontrado. Ejemplo, si se detecta una poliza
con origen de un movimiento nuevo hay que mostrarla en la 
caratula.
