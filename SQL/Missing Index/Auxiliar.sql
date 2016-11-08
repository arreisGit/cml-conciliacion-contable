CREATE NONCLUSTERED INDEX IX_Auxiliar_Modulo_Cuenta_Fecha
ON [dbo].[Auxiliar] ([Modulo],[Cuenta],[Fecha])
INCLUDE (
  [Rama],
  [Mov],
  [Moneda],
  [Cargo],
  [Abono],
  [Aplica],
  [AplicaID]
 )
