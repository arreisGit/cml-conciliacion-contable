SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_SPQ_ConciliacionCont_OrigenContCxp_IVAPorAcreditar') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_SPQ_ConciliacionCont_OrigenContCxp_IVAPorAcreditar
END	

GO

/* =============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2017-02-21

  Description: Obtiene los movimientos que componen
  el auxiliar Cxp IVA Por Acreditar desde el modulo
  de Cxp, con la suficiente iformacion para
  poderlos cruzar "lado a lado" con su póliza contable.
 
  Example: EXEC CUP_SPQ_ConciliacionCont_OrigenContCxp_IVAPorAcreditar 63527, 1, 2017, 1
 ============================================= */


CREATE PROCEDURE dbo.CUP_SPQ_ConciliacionCont_OrigenContCxp_IVAPorAcreditar
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
    Cuenta = m.Proveedor,
    Nombre =  REPLACE(REPLACE(REPLACE(Prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    m.Estatus,
    eV.EsCancelacion,
    Moneda = m.ProveedorMoneda,
    TipoCambio  = m.ProveedorTipoCambio,
    ImporteTotal = conversion_doc.ImporteTotal 
                 * ISNULL(origenCont.Factor,1) 
                 * eV.Factor,
    FluctuacionCambiariaMN = 0,
    ImporteTotalMN = ROUND(
                            (
                               conversion_doc.ImporteTotal 
                             * m.ProveedorTipoCambio 
                            )
                            * ISNULL(origenCont.Factor,1)
                            * eV.Factor 
                     , 4, 1),
    AuxiliarModulo = origenCont.AuxModulo,
    AuxiliaMov = origenCont.AuxMov,
    PolizaID =  pf.DID
  FROM 
    CUP_ConciliacionCont_Tipo_OrigenContable origenCont 
  JOIN Cxp m ON origenCont.Mov = m.Mov
  JOIN Prov ON Prov.Proveedor = m.Proveedor
  JOIN @EstatusValidos eV ON eV.Estatus = m.Estatus
  -- Factor Moneda Documento
  CROSS APPLY( SELECT   
                  FactorTC =   m.TipoCambio / m.ProveedorTipoCambio,
                  ImporteTotal =  ROUND( 
                                         ISNULL(m.Impuestos,0)
                                       * (m.TipoCambio / m.ProveedorTipoCambio)
                                       , 4, 1)
              ) conversion_doc 
  -- Fluctuacion Cambiaria
  CROSS APPLY(SELECT
                DiferenciaCambiaria = SUM(ISNULL(dc.Diferencia_Cambiaria_MN,0))
                                    * ISNULL( origenCont.Factor, 1 )
              FROM 
                CUP_v_CxDiferenciasCambiarias dc
              WHERE
                dc.Modulo = origenCont.Modulo
              AND dc.ModuloID = m.ID) fc
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
    OrigenCont.Tipo = @Tipo 
  AND OrigenCont.UsarAuxiliarNeto = 0
  AND origenCont.Modulo = 'CXP'
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

  UNION 

  --  Une los movimientos que por su naturaleza es mas facil detectar el impacto 
  --  a proveedores desde los auxiliares de Cxp. Como es el caso 
  --  de la Aplicaciones y Endosos donde se puede considerar su Neto.

  SELECT 
    Empleado = @Empleado,
    origenCont.Modulo,
    m.ID,
    m.Mov,
    m.MovId,
    aux.Sucursal,
    m.FechaEmision,
    Cuenta = m.Proveedor,
    Nombre = cf.Nombre,
    m.Estatus,
    aux.EsCancelacion,
    aux.Moneda,
    aux.TipoCambio,
    ImporteTotal = SUM(ISNULL(calc.Neto,0)),
    FluctuacionCambiariaMN = 0,
    ImporteTotalMN = ROUND(SUM(
                                ISNULL(calc.Neto, 0)
                              * ISNULL( movEnOrigen.TipoCambio, ISNULL( primer_tc.TipoCambio, ISNULL(doc.ProveedorTipoCambio, aux.TipoCambio) ) )
                              )
                           , 4, 1),
    AuxiliarModulo = origenCont.AuxModulo,
    AuxiliaMov = origenCont.AuxMov,
    PolizaID  = pf.DID
  FROM 
    CUP_ConciliacionCont_Tipo_OrigenContable origenCont
  JOIN CUP_v_AuxiliarCxp aux ON aux.Modulo = origenCont.Modulo
                            AND aux.Mov    = origenCont.Mov
  -- Excepciones Cuentas
  LEFT JOIN CUP_ConciliacionCont_Excepciones eX ON ex.TipoConciliacion = @Tipo
                                               AND ex.TipoExcepcion = 1
                                               AND ex.Valor = aux.Cuenta
  JOIN rama r ON r.Rama = aux.Rama
  JOIN Prov ON Prov.Proveedor = aux.Cuenta
  JOIN Cxp m ON m.ID = aux.ModuloID
  LEFT JOIN Cxp doc ON doc.Mov   = aux.Aplica
                   AND doc.MovId = aux.AplicaID
  -- MovFlujo Origen
  OUTER APPLY(
                SELECT TOP 1
                  mf.OModulo,
                  mf.OID
                FROM 
                  MovFlujo mf 
                WHERE 
                  mf.DModulo = 'CXP'
                AND mf.DID = doc.ID
                AND mf.OModulo = doc.OrigenTipo
                AND mf.OMov = doc.Origen
                AND mf.OMovID = doc.OrigenID
              ) mfOrigen
    -- Datos del doc en Modulo Origen
  OUTER APPLY ( SELECT TOP 1
                  coms.TipoCambio
                FROM 
                  Compra coms
                WHERE 
                 'COMS'    =  mfOrigen.OModulo 
                AND coms.ID = mfOrigen.OID
                UNION
                SELECT TOP 1
                  gas.TipoCambio
                FROM 
                  Gasto gas
                WHERE 
                 'GAS'    =  mfOrigen.OModulo 
                AND gas.ID = mfOrigen.OID
              ) movEnOrigen
   -- Primer Tc
   OUTER APPLY(SELECT TOP 1 
                 first_aux.TipoCambio
               FROM 
                 Auxiliar first_aux 
               JOIN Rama fr ON fr.Rama = first_aux.Rama 
               WHERE 
                 fr.Mayor = 'CXP'
               AND first_aux.Modulo = 'CXP'
               AND first_aux.ModuloID = doc.ID
               ORDER BY 
                first_aux.ID ASC ) primer_tc
  -- Factor Canceclacion
  CROSS APPLY(SELECT
               Factor  = CASE ISNULL(aux.EsCancelacion,0) 
                           WHEN 1 THEN
                             -1
                           ELSE 
                              1
                          END) fctorCanc 
  -- Fluctuacion Cambiaria
  LEFT JOIN CUP_v_CxDiferenciasCambiarias fc ON fc.Modulo = aux.Modulo
                                            AND fc.ModuloID = aux.ModuloId
                                            AND fc.Documento = aux.Aplica
                                            AND fc.DocumentoID = aux.AplicaID
  -- Clean Fields
  OUTER APPLY (  
                SELECT
                  Nombre = ISNULL(REPLACE(REPLACE(REPLACE(Prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),'')
              ) cf
  -- CALCULADOS
  OUTER APPLY (
               SELECT 
                Cargo = ISNULL(aux.Cargo, 0)
                      * aux.IVAFiscal,
                Abono = ISNULL(aux.Abono, 0)
                      * aux.IVAFiscal,
                Neto  =  ISNULL(aux.Neto, 0)
                      * aux.IVAFiscal  
              ) calc
  -- Poliza Contable
  OUTER APPLY( 
               SELECT TOP 1
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
                                aux.EsCancelacion = 1 
                             AND mf.DID = m.ContID
                             )
                          OR (
                                aux.EsCancelacion = 0
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
  AND origenCont.UsarAuxiliarNeto = 1 
  AND origenCont.Modulo = 'CXP'
  AND r.Mayor = 'CXP'
  AND aux.Ejercicio = @Ejercicio
  AND aux.Periodo = @Periodo
  AND (  origenCont.ValidarOrigen = 0
      OR (  
            origenCont.ValidarOrigen = 1 
          AND ISNULL(origenCont.OrigenTipo,'') = ISNULL(m.OrigenTipo,'')
          AND ISNULL(origenCont.Origen,'') = ISNULL(m.Origen,'')
        )
      )
  -- Filtro Excepciones cuenta
  AND eX.ID IS NULL
  GROUP BY 
    origenCont.Modulo,
    m.ID,
    m.Mov,
    m.MovId,
    aux.Sucursal,
    m.FechaEmision,
    m.Proveedor,
    cf.Nombre,
    Prov.Cuenta,
    m.Estatus,
    aux.EsCancelacion,
    aux.Moneda,
    aux.TipoCambio,
    origenCont.AuxModulo,
    origenCont.AuxMov,
    pf.DID
END