# Poblemas conocidos para la herramienta de conciliacion contable.
## To do
1. Sobre el auxiliar de los Depositos de Core caja para el IVA Trasladado,
hay que revisar si se puede sacar el IVA fiscal de los cobros a los que
aplico el corte. No creo que sea posible, al menos en la configuracion
actual del sistema, pero seria el deber ser.

2. Hay que revisar el escenario de las aplicaciones en la conciliacion
del IVA Por Acreditar. Un ejemplo del caso es la aplicacion MY1495,
donde existe una diferencia entre el tipo de cambio de las entradas
que se estan aplicando contra el de la nota de credito. Lo cual
presenta un escenario natural donde al parecer se necesita de una
fluctuacion que al dia de hoy no se esta realizando.

## En Revision
1. Hay que asegurarse que en el proceso del mapeo entre auxiliares 
y conttabilidad regrese el concepto de cualquiese que sea 
el origen encontrado. Ejemplo, si se detecta una poliza
con origen de un movimiento nuevo hay que mostrarla en la 
caratula.
