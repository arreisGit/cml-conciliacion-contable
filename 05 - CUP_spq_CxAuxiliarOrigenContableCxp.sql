SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_spq_CxAuxiliarOrigenContableCxp') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_spq_CxAuxiliarOrigenContableCxp 
END	

GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-17
-- Last Modified: 2016-10-17 
--
-- Description: Obtiene los movimientos que componen
-- el auxiliar Cxp desde el modulo de  cxp y con la 
-- suficiente iformacion para poderlos cruzar 
-- "lado a lado" con su póliza  contable.
-- 
-- Example: EXEC CUP_spq_CxAuxiliarOrigenContableCxp 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_spq_CxAuxiliarOrigenContableCxp
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
    Moneda = m.ProveedorMoneda,
    TipoCambio  = m.ProveedorTipoCambio,
    ImporteTotal = conversion_doc.ImporteTotal 
                 * ISNULL(origenCont.Factor,1) 
                 * eV.Factor,
    ImporteTotalMN = ROUND(
                            (
                               ( conversion_doc.ImporteTotal * m.ProveedorTipoCambio )
                             + ISNULL(fc.DiferenciaCambiaria,0) 
                            )
                            * ISNULL(origenCont.Factor,1)
                            * eV.Factor 
                     , 4, 1),
    FlutuacionCambiariaMN = ROUND(
                                  ISNULL(fc.DiferenciaCambiaria,0)
                                * ISNULL(origenCont.Factor,1)
                                * eV.Factor 
                           , 4, 1),
    AuxiliarModulo = origenCont.AuxModulo,
    AuxiliaMov = origenCont.AuxMov,
    PolizaID = 
  FROM 
    CUP_CxOrigenContable origenCont 
  JOIN Cxp m ON origenCont.Mov = m.Mov
  JOIN Prov ON Prov.Proveedor = m.Proveedor
  JOIN @EstatusValidos eV ON eV.Estatus = m.Estatus
  -- Factor Ca
  -- Factor Moneda Documento
  CROSS APPLY( SELECT   
                  FactorTC =   m.TipoCambio / m.ProveedorTipoCambio,
                  ImporteTotal =  ROUND(  ( ISNULL(m.Importe,0) + ISNULL(m.Impuestos,0) - ISNULL(m.Retencion,0) )
                                        * (m.TipoCambio / m.ProveedorTipoCambio), 4, 1)
              ) conversion_doc 
  -- Fluctuacion Cambiaria
  CROSS APPLY(SELECT
                DiferenciaCambiaria = SUM(ISNULL(dc.Diferencia_Cambiaria_MN,0))
              FROM 
                CUP_v_CxDiferenciasCambiarias dc
              WHERE
                dc.Modulo = origenCont.Modulo
              AND dc.ModuloID = m.ID) fc

  WHERE
    OrigenCont.UsarAuxiliarNeto = 0
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

  UNION 

  --  Une los movimientos que por su naturaleza es mas facil detectar el impacto 
  --  a proveedores desde los auxiliares de Cxp. Como es el caso 
  --  de la Aplicaciones y Endosos donde se puede considerar su Neto.

  SELECT 
    origenCont.Modulo,
    m.ID,
    m.Mov,
    m.MovId,
    aux.Sucursal,
    m.FechaEmision,
    m.Proveedor,
    ProvNombre =  REPLACE(REPLACE(REPLACE(Prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    ProvCuenta =  Prov.Cuenta,
    m.Estatus,
    aux.EsCancelacion,
    aux.Moneda,
    aux.TipoCambio,
    ImporteTotal = SUM(ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0)),
    ImporteTotalMN = ROUND(SUM( ( ISNULL(aux.Cargo,0) - ISNULL(aux.Abono,0) ) * aux.TipoCambio), 4, 1),
    FlutuacionCambiariaMN = ROUND(
                              SUM( ISNULL(fc.Diferencia_Cambiaria_MN,0) * -1 * ISNULL(fctorCanc.Factor,1))
                            ,4,1),
    AuxiliarModulo = origenCont.AuxModulo,
    AuxiliaMov = origenCont.AuxMov,
    PolizaID  = 
  FROM 
    CUP_CxOrigenContable origenCont
  JOIN Auxiliar aux ON aux.Modulo = origenCont.Modulo
                   AND aux.Mov    = origenCont.Mov
  JOIN rama r ON r.Rama = aux.Rama
  JOIN Prov ON Prov.Proveedor = aux.Cuenta
  JOIN Cxp m ON m.ID = aux.ModuloID
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
  WHERE 
      origenCont.UsarAuxiliarNeto = 1 
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
  GROUP BY 
    origenCont.AuxModulo,
    origenCont.AuxMov,
    aux.Sucursal,
    m.FechaEmision,
    m.Proveedor,
    REPLACE(REPLACE(REPLACE(Prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    Prov.Cuenta,
    origenCont.Modulo,
    m.ID,
    m.Mov,
    m.MovId,
    m.Estatus,
    aux.EsCancelacion,
    aux.Moneda,
    aux.TipoCambio
END