SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_spq_CxAuxiliarModulo') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_spq_CxAuxiliarModulo 
END	


GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-17
-- Last Modified: 2016-10-17 
--
-- Description: Obtiene los movimientos que componen
-- el auxiliar de Cxc/Cxp, con la suficiente informacion
-- para poderlos cruzar "lado a lado" con su póliza 
-- contable.
-- 
-- Example: EXEC CUP_spq_CxAuxiliarModulo 'CXP', 2016, 9
-- =============================================


CREATE PROCEDURE dbo.CUP_spq_CxAuxiliarModulo
  @Modulo CHAR(5),
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
    EsCancelacion BIT NOT NULL 
    PRIMARY KEY (
                  Estatus,
                  EsCancelacion
                )
  )
  INSERT INTO @EstatusValidos
  ( 
    Estatus,
    EsCancelacion
  )
  VALUES 
    ( 'CONCLUIDO', 0 ),
    ( 'PENDIENTE', 0 ),
    ( 'CANCELADO', 0 ), 
    ( 'CANCELADO', 1 )

  SELECT
    origenCont.AuxModulo,
    origenCont.AuxMov,
    m.Sucursal,
    m.FechaEmision,
    m.Proveedor,
    ProvNombre =  REPLACE(REPLACE(REPLACE(Prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    ProvCuenta =  Prov.Cuenta,
    origenCont.Modulo,
    m.ID,
    m.Mov,
    m.MovId,
    m.Estatus,
    eV.EsCancelacion,
    m.ProveedorMoneda,
    m.ProveedorTipoCambio,
    conversion_doc.ImporteTotal,
    ImporteTotalMN = ROUND(conversion_doc.ImporteTotal * m.ProveedorTipoCambio, 4, 1),
    FlutuacionCambiariaMN = ROUND(ISNULL(fc.DiferenciaCambiaria,0), 4, 1),
    PolizaID = pf.DID
  FROM 
    CUP_CxOrigenContable origenCont 
  JOIN Cxp m ON origenCont.Mov = m.Mov
  JOIN Prov ON Prov.Proveedor = m.Proveedor
  JOIN @EstatusValidos eV ON eV.Estatus = m.Estatus
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
  -- Poliza Contable: Para los movimientos cancelados
  -- se debe trae la poliza correcta tanto para la provision
  -- como para la cancelacion.
  LEFT JOIN movFlujo pf ON pf.OModulo = origenCont.Modulo
                       AND pf.OId = m.ID
                       AND pf.DModulo = 'CONT'
                       AND (  
                              ( 
                                  ISNULL(m.Estatus,'') = 'CANCELADO'
                              AND (   
                                    (     
                                        eV.EsCancelacion = 0 
                                    AND pf.DID < m.ContID
                                    )
                                  OR (   
                                        eV.EsCancelacion = 1 
                                    AND pf.DID = m.ContId
                                    )
                                  )
                              )
                           OR (  
                                ISNULL(m.Estatus,'') <> 'CANCELADO' 
                              AND pf.DID = m.ContID
                              )
                           )
  
  WHERE   
    origenCont.Modulo = 'CXP'
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