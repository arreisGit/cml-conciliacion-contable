IF NOT EXISTS(SELECT 
                * 
              FROM
                sys.indexes
              WHERE
                name = 'IX_Auxiliar_Modulo_Cuenta_Fecha'
              AND object_id = OBJECT_ID('Auxiliar'))
BEGIN
        
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

END

GO

IF NOT EXISTS(SELECT 
                * 
              FROM
                sys.indexes
              WHERE
                name = 'IX_Auxiliar_Modulo_Mov'
              AND object_id = OBJECT_ID('Auxiliar'))
BEGIN
        

  CREATE NONCLUSTERED INDEX [IX_Auxiliar_Modulo_Mov]
  ON [dbo].Auxiliar (Modulo, Mov)
  INCLUDE (
            ID,
            Empresa,
            Sucursal,
            Rama,
            MovID,
            ModuloID,
            Moneda,
            TipoCambio,
            Cuenta,
            Ejercicio,
            Periodo,
            Fecha,
            Cargo,
            Abono,
            Aplica,
            AplicaID,
            EsCancelacion
           )
END