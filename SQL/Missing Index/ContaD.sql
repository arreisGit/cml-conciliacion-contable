IF NOT EXISTS(SELECT 
                * 
              FROM
                sys.indexes
              WHERE
                name = 'IX_ContD_FechaContable'
              AND object_id = OBJECT_ID('ContD'))
BEGIN
        
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

END

IF NOT EXISTS(SELECT 
                * 
              FROM
                sys.indexes
              WHERE
                name = 'IX_ContD_Cuenta_FechaContable'
              AND object_id = OBJECT_ID('ContD'))
BEGIN
        
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

END