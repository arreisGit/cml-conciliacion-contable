CREATE NONCLUSTERED INDEX [IX_ContD_FechaContable]
ON [dbo].[ContD] ([FechaContable])
INCLUDE 
(
  [ID],
  [SucursalContable],
  [Cuenta],
  [SubCuenta],
  [Debe],
  [Haber]
 )


CREATE NONCLUSTERED INDEX [IX_ContD_Cuenta_FechaContable]
ON [dbo].[ContD] ([Cuenta],[FechaContable])
INCLUDE 
(
  [ID],
  [Sucursal],
  [SubCuenta],
  [Debe],
  [Haber]
)
