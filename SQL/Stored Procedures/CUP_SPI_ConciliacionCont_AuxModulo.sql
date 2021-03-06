SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPI_ConciliacionCont_AuxModulo') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxModulo 
END	

GO

/* =============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2016-10-24

  Description: Procedimiento encargado de hacer el llamado
  individual a los procesos que llenan el auxiliar del modulo
  en la herramienta de conciliacion contable.

  Example: EXEC CUP_SPI_ConciliacionCont_AuxModulo 63527, 1, 2016, 9
 ============================================= */


CREATE PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxModulo
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 
  
  SET NOCOUNT ON;

  DELETE CUP_ConciliacionCont_AuxModulo
  WHERE Empleado = @Empleado

  -- Saldo Proveedores
  IF @Tipo = 1
  BEGIN
    
    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCxp @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCOMS @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContGas @Empleado, @Tipo, @Ejercicio, @Periodo

  END

  -- IVA Por Acreditar
  IF @Tipo = 2
  BEGIN
    
    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCxp_IVAPorAcreditar @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCOMS_IVAPorAcreditar @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContGas_IVAPorAcreditar @Empleado, @Tipo, @Ejercicio, @Periodo

  END
 
  -- Saldo Clientes
  IF @Tipo = 3 
  BEGIN
    
    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCxc @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContVtas @Empleado, @Tipo, @Ejercicio, @Periodo

  END 

  -- IVA TRASLADADO
  IF @Tipo = 4 
  BEGIN
    
    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContCxc_IVATrasladado @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContVtas_IVATrasladado @Empleado, @Tipo, @Ejercicio, @Periodo

    INSERT INTO CUP_ConciliacionCont_AuxModulo
    EXEC CUP_SPQ_ConciliacionCont_OrigenContDin_IVATrasladado @Empleado, @Tipo, @Ejercicio, @Periodo

  END 

END