SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_OrigenContDin_IVATrasladado') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_OrigenContDin_IVATrasladado
END	

GO

/* =============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2017-01-23

  Description: Obtiene los movimientos que componen
  el auxiliar Cxc IVA Trasladado desde el modulo de Din 
  y con la  suficiente iformacion para poderlos cruzar 
  "lado a lado" con su póliza  contable.
 
  Example: EXEC CUP_SPQ_ConciliacionCont_OrigenContDin_IVATrasladado 63527, 4, 2017, 1
============================================= */


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_OrigenContDin_IVATrasladado
  @Empleado INT,
  @Tipo INT,
  @Ejercicio INT,
  @Periodo INT
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
    ( 'CONCLUIDO', 0,  1 ),
    ( 'PENDIENTE', 0,  1 ),
    ( 'CANCELADO', 0,  1 ), 
    ( 'CANCELADO', 1, -1 )

  -- Depositos de Cajas
  SELECT
    Empleado = @Empleado,
    origenCont.Modulo,
    m.ID,
    m.Mov,
    m.MovId,
    m.Sucursal,
    m.FechaEmision,
    Cuenta = m.CtaDinero,
    Nombre =  REPLACE(REPLACE(REPLACE(cd.Descripcion,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    m.Estatus,
    eV.EsCancelacion,
    Moneda = m.Moneda,
    TipoCambio  = m.TipoCambio,
    ImporteTotal = ISNULL(m.Importe,0)
                 * ISNULL(origenCont.Factor,1)
                 * ISNULL(m.IVAFiscal,0) 
                 * eV.Factor,
    FluctuacionCambiariaMN = 0,
    ImporteTotalMN = ROUND(
                             ( ISNULL(m.Importe,0) * m.TipoCambio )
                            * ISNULL(origenCont.Factor,1)
                            * ISNULL(m.IVAFiscal,0)
                            * eV.Factor 
                     , 4, 1),
    AuxiliarModulo = origenCont.AuxModulo,
    AuxiliaMov = origenCont.AuxMov,
    PolizaID =  pf.DID
  FROM 
    CUP_ConciliacionCont_Tipo_OrigenContable origenCont 
  JOIN CUP_v_DepositosCortesCaja m ON origenCont.Mov = m.Mov
  JOIN Movtipo t ON t.Modulo = 'DIN'
                AND t.Mov = m.Mov
  JOIN CtaDinero cd ON cd.CtaDinero = m.CtaDinero
  JOIN @EstatusValidos eV ON eV.Estatus = m.Estatus
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
    OrigenCont.Tipo = @Tipo 
  AND OrigenCont.UsarAuxiliarNeto = 0
  AND origenCont.Modulo = 'DIN'
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