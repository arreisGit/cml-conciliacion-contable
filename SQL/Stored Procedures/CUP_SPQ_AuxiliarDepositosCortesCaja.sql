SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_AuxiliarDepositosCortesCaja') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_AuxiliarDepositosCortesCaja
END	

GO

/* =============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2016-12-13

  Description: Regresa un listado de los depositos que aplicaron a solicitudes
  de deposito disparadas por cortes de caja ( chica o tombola ) pero en el formato de auxiliares.

  Example: EXEC CUP_SPQ_AuxiliarDepositosCortesCaja '2016-10-01','2016-10-31', NULL
============================================= */

CREATE PROCEDURE dbo.CUP_SPQ_AuxiliarDepositosCortesCaja
  @FechaD DATETIME,
  @FechaA DATETIME,
  @Sucursal INT = NULL
AS BEGIN 

  SET NOCOUNT ON;

  -- Tabla utilizada a modo de "workaround" 
  -- para poder simular el efecto de "EsCancelacion"
  -- directo en el modulo.
  DECLARE @EstatusValidos TABlE
  (
    Estatus VARCHAR(15) NOT NULL,
    EsCancelacion BIT NOT NULL ,
    Factor SMALLINT NOT NULL,
    PRIMARY KEY (
                  Estatus,
                  EsCancelacion
                )
  )
  
  INSERT INTO @EstatusValidos
  ( 
    Estatus,
    EsCancelacion,
    Factor
  )
  VALUES 
   ( 'CONCLUIDO', 0,  1)
  ,( 'CANCELADO', 0,  1 )
  ,( 'CANCELADO', 1, -1 )
  

  IF OBJECT_ID('tempdb..#CUP_DepositosCortesCaja') IS NOT NULL
   DROP TABLE #CUP_DepositosCortesCaja

  CREATE TABLE #CUP_DepositosCortesCaja
  (
    Empresa VARCHAR(5) NOT NULL,
    Sucursal INT NOT NULL,
    ID INT NOT NULL,
    Mov CHAR(20) NOT NULL,
    Movid	VARCHAR(20) NOT NULL,
    FechaEmision DATETIME NOT NULL,
    Ejercicio	INT NOT NULL,
    Periodo INT NOT NULL,
    Estatus	VARCHAR(15) NOT NULL,
    CtaDinero CHAR(10)	NOT NULL,
    CtaDineroDestino CHAR(10) NULL,
    Aplica CHAR(20) NOT NULL,
    AplicaID VARCHAR(20) NOT NULL,
    Moneda CHAR(10) NOT NULL,
    TipoCambio FLOAT NOT NULL,
    Cargo DECIMAL(18,4) NOT NULL,
    Abono DECIMAL(18,4) NOT NULL,
    FormaPago	VARCHAR(50) NULL,
    IVAFiscal FLOAT NOT NULL,
    CorteID INT NOT NULL,
    CorteMov CHAR(20) NOT NULL,
    CorteMovID VARCHAR(20) NULL
  )

  CREATE NONCLUSTERED INDEX [IX_#CUP_DepositosCortesCaja_Estatus]
  ON [dbo].[#CUP_DepositosCortesCaja] ( Estatus )
  INCLUDE ( 
            Empresa,
            Sucursal,
            ID,
            Mov,
            Movid,
            FechaEmision,
            Ejercicio,
            Periodo,
            CtaDinero,
            CtaDineroDestino,
            Aplica,
            AplicaID,
            Moneda,
            TipoCambio,
            Cargo,
            Abono,
            FormaPago,
            IVAFiscal,
            CorteID,
            CorteMov,
            CorteMovID
          )


  INSERT INTO #CUP_DepositosCortesCaja 
  (
    Empresa,
    Sucursal,
    ID,
    Mov,
    Movid,
    FechaEmision,
    Ejercicio,
    Periodo,
    Estatus,
    CtaDinero,
    CtaDineroDestino,
    Aplica,
    AplicaID,
    Moneda,
    TipoCambio,
    Cargo,
    Abono,
    FormaPago,
    IVAFiscal,
    CorteID,
    CorteMov,
    CorteMovID
  )
  SELECT 
    depositos.Empresa,
    depositos.Sucursal,
    depositos.ID,
    depositos.Mov,
    depositos.Movid,
    depositos.FechaEmision,
    depositos.Ejercicio,
    depositos.Periodo,
    depositos.Estatus,
    depositos.CtaDinero,
    depositos.CtaDineroDestino,
    depositos.Aplica,
    depositos.AplicaID,
    depositos.Moneda,
    depositos.TipoCambio,
    Cargo = calc.Cargo,
    Abono = calc.Abono,
    depositos.FormaPago,
    IVAFiscal = ISNULL(depositos.IVAFiscal,0),
    depositos.CorteID,
    depositos.CorteMov,
    depositos.CorteMovID
  FROM 
    CUP_v_DepositosCortesCaja depositos
  -- Cargos Abonos ( para mantener el formato del auxiliar )
  CROSS APPLY (
              SELECT 
                Cargo = CASE
                          WHEN ISNULL(depositos.Importe,0) <= 0 THEN
                            ABS(ISNULL(depositos.Importe,0))
                          ELSE 
                            0
                        END,
                Abono = CASE
                          WHEN ISNULL(depositos.Importe,0) > 0 THEN
                            ISNULL(depositos.Importe,0)
                          ELSE 
                            0
                        END
              ) calc
  WHERE
    depositos.FechaEmision BETWEEN @FechaD AND @FechaA
  AND depositos.Sucursal = ISNULL(@Sucursal, depositos.Sucursal)

  IF OBJECT_ID('tempdb..#CUP_AuxDepositosCortesCaja') IS NOT NULL
  BEGIN
   
    INSERT INTO #CUP_AuxDepositosCortesCaja 
    (
      Empresa,
      Sucursal,
      ID,
      Mov,
      Movid,
      FechaEmision,
      Ejercicio,
      Periodo,
      Estatus,
      CtaDinero,
      CtaDineroDestino,
      Aplica,
      AplicaID,
      Moneda,
      TipoCambio,
      Cargo,
      Abono,
      Neto,
      FormaPago,
      IVAFiscal,
      CorteID,
      CorteMov,
      CorteMovID,
      EsCancelacion
    )
    SELECT  
      depositos.Empresa,
      depositos.Sucursal,
      depositos.Id,
      depositos.Mov,
      depositos.MovId,
      Fecha = depositos.FechaEmision,
      depositos.Ejercicio,
      depositos.Periodo,
      depositos.Estatus,
      depositos.CtaDinero,
      depositos.CtaDineroDestino,
      depositos.Aplica,
      depositos.AplicaID,
      depositos.Moneda,
      depositos.TipoCambio,
      Cargo =  ROUND( ISNULL( calc.Cargo, 0), 4, 1),
      Abono = ROUND( ISNULL( calc.Abono, 0), 4, 1),
      Neto = ROUND( ISNULL( calc.Neto, 0) , 4, 1),
      depositos.FormaPago,
      depositos.IVAFiscal,
      depositos.CorteID,
      depositos.CorteMov,
      depositos.CorteMovID,
      eV.EsCancelacion
    FROM 
      #CUP_DepositosCortesCaja depositos
    JOIN  @EstatusValidos eV ON eV.Estatus = depositos.Estatus
    -- calculados
    CROSS APPLY ( 
                  SELECT 
                    Cargo = ISNULL(depositos.Cargo,0) 
                           * ev.Factor,
                    Abono = ISNULL(depositos.Abono,0)
                          * ev.Factor,
                    Neto = (
                             ISNULL(depositos.Cargo,0) 
                           - ISNULL(depositos.Abono,0)
                            )
                           * ev.Factor
                ) calc
  END
  ELSE 
  BEGIN
    SELECT  
      depositos.Empresa,
      depositos.Sucursal,
      depositos.Id,
      depositos.Mov,
      depositos.MovId,
      Fecha = depositos.FechaEmision,
      depositos.Ejercicio,
      depositos.Periodo,
      depositos.Estatus,
      depositos.CtaDinero,
      depositos.CtaDineroDestino,
      depositos.Aplica,
      depositos.AplicaID,
      depositos.Moneda,
      depositos.TipoCambio,
      Cargo =  ROUND( ISNULL( calc.Cargo, 0), 4, 1),
      Abono = ROUND( ISNULL( calc.Abono, 0), 4, 1),
      Neto = ROUND( ISNULL( calc.Neto, 0) , 4, 1),
      depositos.FormaPago,
      depositos.IVAFiscal,
      depositos.CorteID,
      depositos.CorteMov,
      depositos.CorteMovID,
      eV.EsCancelacion
    FROM 
      #CUP_DepositosCortesCaja depositos
    JOIN  @EstatusValidos eV ON eV.Estatus = depositos.Estatus
    -- calculados
    CROSS APPLY ( 
                  SELECT 
                    Cargo = ISNULL(depositos.Cargo,0) 
                           * ev.Factor,
                    Abono = ISNULL(depositos.Abono,0)
                          * ev.Factor,
                    Neto = (
                             ISNULL(depositos.Cargo,0) 
                           - ISNULL(depositos.Abono,0)
                            )
                           * ev.Factor
                ) calc
  END
END