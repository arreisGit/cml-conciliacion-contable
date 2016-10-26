SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_OrigenContComs') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_OrigenContComs 
END	

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-24
--
-- Description: Obtiene los movimientos que componen
-- el auxiliar Cxp desde el modulo de  Compras y con la 
-- suficiente iformacion para poderlos cruzar 
-- "lado a lado" con su póliza  contable.
-- 
-- Example: EXEC CUP_SPQ_ConciliacionCont_OrigenContComs 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_OrigenContComs
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

  DECLARE
    @FechaInicio DATE = CAST(CAST(@Ejercicio AS VARCHAR)
                                  + '-' 
                                  + CAST(@Periodo AS VARCHAR)
                                  + '-01' AS DATE)
  
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
    ( 'CONCLUIDO', 0,  1 ),
    ( 'PENDIENTE', 0,  1 ),
    ( 'CANCELADO', 0,  1 ), 
    ( 'CANCELADO', 1, -1 )

  SELECT
    origenCont.Modulo,
    m.ID,
    m.Mov,
    m.MovId,
    m.Sucursal,
    m.FechaEmision,
    m.Proveedor,
    ProvNombre =  REPLACE(REPLACE(REPLACE(Prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    ProvCuenta =  Prov.Cuenta,
    m.Estatus,
    eV.EsCancelacion,
    Moneda = m.Moneda,
    TipoCambio  = m.TipoCambio,
    ImporteTotal = calc.ImporteTotal
                 * ISNULL(origenCont.Factor,1) 
                 * eV.Factor,
    FluctuacionCambiariaMN = 0,
    ImporteTotalMN = ROUND(
                            calc.ImporteTotal
                          * m.TipoCambio
                          * ISNULL(origenCont.Factor,1) 
                          * eV.Factor
                     , 4, 1),

    AuxiliarModulo = origenCont.AuxModulo,
    AuxiliaMov = origenCont.AuxMov,
    PolizaID =  pf.DID
  FROM 
    CUP_CxOrigenContable origenCont 
  JOIN Compra m ON origenCont.Mov = m.Mov
  JOIN Prov ON Prov.Proveedor = m.Proveedor
  JOIN @EstatusValidos eV ON eV.Estatus = m.Estatus
  -- CALC
  CROSS APPLY(
              SELECT
                ImporteTotal = ISNULL(m.Importe,0) 
                             + ISNULL(m.Impuestos,0)
                             - ISNULL(m.Retencion,0)
                             - ISNULL(m.DescuentoGlobal,0)
             ) calc
  -- Poliza Contable
  OUTER APPLY( 
               SELECT 
                 mf.DID
               FROM 
                MovFlujo mf
               WHERE 
                 mf.DModulo = 'CONT'
               AND mf.OModulo = origenCont.Modulo
               AND mf.OID = m.ID               
               AND ( 
                      (   
                          m.Estatus = 'CANCELADO'
                      AND (
                             (
                                eV.EsCancelacion = 1 
                             AND mf.DID = m.ContID
                             )
                          OR (
                                eV.EsCancelacion = 0
                             AND mf.DID < m.ContID
                             )
                          )
                      )
                  OR  (
                        m.Estatus <> 'CANCELADO'
                      AND mf.DID = m.ContID
                      )
                  )
              ) pf
  WHERE
    OrigenCont.UsarAuxiliarNeto = 0
  AND origenCont.Modulo = 'COMS'
  AND (  origenCont.ValidarOrigen = 0
      OR (  
            origenCont.ValidarOrigen = 1 
          AND ISNULL(origenCont.OrigenTipo,'') = ISNULL(m.OrigenTipo,'')
          AND ISNULL(origenCont.Origen,'') = ISNULL(m.Origen,'')
        )
      )
  AND m.Ejercicio = @Ejercicio
  AND m.Periodo = @Periodo
  AND m.Estatus IN ('PENDIENTE','CANCELADO','CONCLUIDO')
END