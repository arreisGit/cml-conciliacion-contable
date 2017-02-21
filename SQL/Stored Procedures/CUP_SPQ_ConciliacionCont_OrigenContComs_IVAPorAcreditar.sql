SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_OrigenContComs_IVAPorAcreditar') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_OrigenContComs_IVAPorAcreditar 
END	

GO

/* =============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2017-02-21

  Description: Obtiene los movimientos que componen
  el auxiliar Cxp IVA Por Acreditar desde el modulo
  de Compras, con la suficiente iformacion para
  poderlos cruzar "lado a lado" con su póliza contable.
 
  Example: EXEC CUP_SPQ_ConciliacionCont_OrigenContComs_IVAPorAcreditar 63527, 1, 2017, 1
 ============================================= */

CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_OrigenContComs_IVAPorAcreditar
  @Empleado  INT,
  @Tipo      INT,
  @Ejercicio INT,
  @Periodo   INT
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

  IF @Tipo = 2
  BEGIN
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
  END

  SELECT
    Empleado = @Empleado,
    origenCont.Modulo,
    m.ID,
    m.Mov,
    m.MovId,
    m.Sucursal,
    m.FechaEmision,
    Cuenta =m.Proveedor,
    Nombre =  REPLACE(REPLACE(REPLACE(Prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    m.Estatus,
    eV.EsCancelacion,
    Moneda = m.Moneda,
    TipoCambio  = m.TipoCambio,
    ImporteTotal = calc.ImporteTotal
                  * ISNULL(origenCont.Factor,1) 
                  * eV.Factor,
    FluctuacionCambiariaMN = ISNULL(fc.DiferenciaCambiaria,0),
    ImporteTotalMN = ROUND(
                            (
                              calc.ImporteTotal
                            * m.TipoCambio
                            * ISNULL(origenCont.Factor,1) 
                            * eV.Factor
                            )
                          + ISNULL(fc.DiferenciaCambiaria,0)
                      , 4, 1),
    AuxiliarModulo = origenCont.AuxModulo,
    AuxiliaMov = origenCont.AuxMov,
    PolizaID =  pf.DID
  FROM 
    CUP_ConciliacionCont_Tipo_OrigenContable origenCont 
  JOIN Compra m ON origenCont.Mov = m.Mov
  JOIN Prov ON Prov.Proveedor = m.Proveedor
  JOIN @EstatusValidos eV ON eV.Estatus = m.Estatus
  -- Fluctuacion Cambiaria
  OUTER APPLY(SELECT
                DiferenciaCambiaria = SUM
                                      ( 
                                         ISNULL( dc.Diferencia_Cambiaria_MN, 0)
                                       * ISNULL(dc.IVAFiscal,0) 
                                      )
                                    * ISNULL( origenCont.Factor, 1 )
                                    * ev.Factor
              FROM 
                CUP_v_CxDiferenciasCambiarias dc
              WHERE
                dc.Modulo = origenCont.Modulo
              AND dc.ModuloID = m.ID) fc
  -- CALC
  CROSS APPLY(
              SELECT
                ImporteTotal = ISNULL(m.Impuestos,0)
              ) calc
  -- Excepciones Cuentas
  LEFT JOIN CUP_ConciliacionCont_Excepciones eX ON ex.TipoConciliacion = @Tipo
                                               AND ex.TipoExcepcion = 1
                                               AND ex.Valor = m.Proveedor 
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
    origenCont.Tipo = @Tipo
  AND origenCont.UsarAuxiliarNeto = 0
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
  -- Filtro Excepciones cuenta
  AND eX.ID IS NULL
 
END