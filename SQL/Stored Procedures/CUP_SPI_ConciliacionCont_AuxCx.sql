SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPI_ConciliacionCont_AuxCx') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxCx
END	


GO

/* =============================================
 Created by:    Enrique Sierra Gtez
 Creation Date: 2016-10-13

 Description: Obtiene los auxiliares de
 Cxc o Cxp con la suficiente informacion
 para poder verificar el saldo de la cartera
 durante la conciliacion contaable

 Example: EXEC CUP_SPI_ConciliacionCont_AuxCx 63527, 3, 2016, 10 
============================================= */


CREATE PROCEDURE dbo.CUP_SPI_ConciliacionCont_AuxCx
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

  SET NOCOUNT ON;
  
  DELETE CUP_ConciliacionCont_AuxCx
  WHERE Empleado = @Empleado

  -- Saldo Proveedores
  IF @TIPO = 1
  BEGIN
    INSERT INTO
      CUP_ConciliacionCont_AuxCx
    (
      Empleado,
      Rama,
      AuxID,
      Sucursal,
      Cuenta,
      Mov,
      MovID,
      Modulo,
      ModuloID,
      Moneda,
      TipoCambio,
      Ejercicio,
      Periodo,
      Fecha,
      Cargo,
      Abono,
      Neto,
      CargoMN,
      AbonoMN,
      NetoMN,
      FluctuacionMN,
      TotalMN,
      EsCancelacion,
      Aplica,
      AplicaID,
      OrigenModulo,
      OrigenMov,
      OrigenMovID
    )
    EXEC CUP_SPQ_ConciliacionCont_AuxSaldosCxp @Empleado, @Tipo, @Ejercicio, @Periodo
    
  END

  -- Iva X Acreeditar
  IF @TIPO = 2
  BEGIN
    INSERT INTO
      CUP_ConciliacionCont_AuxCx
    (
      Empleado,
      Rama,
      AuxID,
      Sucursal,
      Cuenta,
      Mov,
      MovID,
      Modulo,
      ModuloID,
      Moneda,
      TipoCambio,
      Ejercicio,
      Periodo,
      Fecha,
      Cargo,
      Abono,
      Neto,
      CargoMN,
      AbonoMN,
      NetoMN,
      FluctuacionMN,
      TotalMN,
      EsCancelacion,
      Aplica,
      AplicaID,
      OrigenModulo,
      OrigenMov,
      OrigenMovID
    )
    EXEC CUP_SPQ_ConciliacionCont_AuxCxpIVAPorAcreditar @Empleado, @Tipo, @Ejercicio, @Periodo

  END
  
  -- Saldos Ctes
  IF @Tipo = 3 
  BEGIN
    INSERT INTO
      CUP_ConciliacionCont_AuxCx
    (
      Empleado,
      Rama,
      AuxID,
      Sucursal,
      Cuenta,
      Mov,
      MovID,
      Modulo,
      ModuloID,
      Moneda,
      TipoCambio,
      Ejercicio,
      Periodo,
      Fecha,
      Cargo,
      Abono,
      Neto,
      CargoMN,
      AbonoMN,
      NetoMN,
      FluctuacionMN,
      TotalMN,
      EsCancelacion,
      Aplica,
      AplicaID,
      OrigenModulo,
      OrigenMov,
      OrigenMovID
    )
    EXEC CUP_SPQ_ConciliacionCont_AuxSaldosCxc @Empleado, @Tipo, @Ejercicio, @Periodo
  END

  -- IVA Trasladado
  IF @Tipo = 4 
  BEGIN
    INSERT INTO
      CUP_ConciliacionCont_AuxCx
    (
      Empleado,
      Rama,
      AuxID,
      Sucursal,
      Cuenta,
      Mov,
      MovID,
      Modulo,
      ModuloID,
      Moneda,
      TipoCambio,
      Ejercicio,
      Periodo,
      Fecha,
      Cargo,
      Abono,
      Neto,
      CargoMN,
      AbonoMN,
      NetoMN,
      FluctuacionMN,
      TotalMN,
      EsCancelacion,
      Aplica,
      AplicaID,
      OrigenModulo,
      OrigenMov,
      OrigenMovID
    )
    EXEC CUP_SPQ_ConciliacionCont_AuxCxcIVATrasladado @Empleado, @Tipo, @Ejercicio, @Periodo
  END
END