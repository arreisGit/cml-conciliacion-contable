SET ANSI_NULLS, ANSI_WARNINGS ON;

GO

IF EXISTS (SELECT * 
		   FROM SYSOBJECTS 
		   WHERE ID = OBJECT_ID('dbo.CUP_spq_CxAuxiliar') AND 
				 TYPE = 'P')
BEGIN
  DROP PROCEDURE dbo.CUP_spq_CxAuxiliar 
END	


GO

-- =============================================
-- Created by:    Enrique Sierra Gtez
-- Creation Date: 2016-10-13
-- Last Modified: 2016-10-17 
--
-- Description: Obtiene los auxiliares de
-- Cxc o Cxp con la suficiente informacion
-- para poder verificar el saldo de la cartera
--
-- Example: EXEC CUP_spq_CxAuxiliar 'CXP', 2016,9
-- =============================================


CREATE PROCEDURE dbo.CUP_spq_CxAuxiliar
  @Modulo CHAR(5),
  @Ejercicio INT,
  @Periodo INT
AS BEGIN 

  DECLARE
    @FechaInicio DATE = CAST(CAST(@Ejercicio AS VARCHAR)
                                  + '-' 
                                  + CAST(@Periodo AS VARCHAR)
                                  + '-01' AS DATE)


  -- Detalle Auxiliar
  SELECT   
    AuxID  = aux.ID,
    aux.Fecha,
    aux.Sucursal,
    Proveedor = aux.Cuenta,
    ProvNombre = REPLACE(REPLACE(REPLACE(prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    ProvCta = REPLACE(REPLACE(REPLACE(prov.Cuenta,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    aux.Modulo,
    aux.ModuloID,
    aux.Mov,
    aux.MovID,
    aux.Moneda,
    aux.TipoCambio,
    Cargo = ISNULL(aux.Cargo,0),
    Abono = ISNULL(aux.Abono,0),
    Neto = calc.Neto,
    CargoMN = ROUND(ISNULL(aux.Cargo,0) * aux.TipoCambio,4,1),
    AbonoMN = ROUND(ISNULL(aux.Abono,0) * aux.TipoCambio,4,1),
    NetoMN =  ROUND(ISNULL(calc.Neto,0) * aux.TipoCambio,4,1),
    FluctuacionMN  = ROUND(calc.FluctuacionMN * -1 * ISNULL(fctorCanc.Factor,1),4,1),
    TotalMN = ROUND(  
                    (calc.Neto * aux.TipoCambio)
                  + (calc.FluctuacionMN * -1 * ISNULL(fctorCanc.Factor,1))
              ,4,1),
    aux.Aplica,
    aux.AplicaID,
    aux.EsCancelacion,
    OrigenModulo = ISNULL(p.OrigenTipo,''),
    OrigenModuloID = ISNULL(CAST(ISNULL(c.ID,g.ID) AS VARCHAR),''),
    OrigenMov = ISNULL(p.Origen,''),
    OrigenMovID = ISNULL(p.OrigenID,''),
    OrigenPoliza = ISNULL(pol.OrigenModulo,''),
    PolizaID = pol.ID,
    PolizaMov = pol.Mov,
    PolizaMovId = pol.MovID
  FROM
    Auxiliar aux 
  JOIN Rama r ON r.Rama = aux.Rama
  JOIN Prov ON prov.Proveedor = Aux.Cuenta
  JOIN Movtipo t ON t.Modulo = aux.Modulo 
                AND  t.Mov  = aux.Mov
  LEFT JOIN MovTipo at ON at.Modulo = aux.Modulo
                      AnD at.Mov = aux.Aplica
  LEFT JOIN Cxp p ON 'CXP' = aux.Modulo
                 AND p.ID = aux.ModuloID      
  LEFT JOIN Compra c ON 'COMS' = p.OrigenTipo
                    AND c.Mov = p.Origen
                    AND c.MovID = p.OrigenID
  LEFT JOIN Gasto g ON 'GAS' = p.OrigenTipo
                    AND g.Mov = p.Origen
                    AND g.MovID = p.OrigenID
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
 -- Campos Calculados
   CROSS APPLY ( SELECT   
                   Neto = ISNULL(aux.Cargo,0) - ISNULL( aux.Abono,0),
                   FluctuacionMN  = ISNULL(fc.Diferencia_Cambiaria_MN,0)
                ) Calc
  -- Poliza  Contable: Para los movimientos cancelados
  -- se debe trae la poliza correcta tanto para la provision
  -- como para la cancelacion.
  OUTER APPLY(SELECT TOP 1
                OrigenModulo = df.OModulo,
                ID = df.DID,
                Mov = df.DMov,
                MovID = df.DMovID
              FROM 
                MovFlujo mf
              JOIN MovFlujo df ON df.OModulo = mf.OModulo
                              AND df.OID = mf.OID
                              AND df.DModulo = 'CONT'
                              AND (  
                                    ( 
                                      ISNULL(p.Estatus,'') = 'CANCELADO'
                                    AND  (   
                                              (     
                                                 aux.EsCancelacion = 0 
                                              AND df.DID < mf.DID
                                              )
                                          OR  (   
                                                  aux.EsCancelacion = 1 
                                               AND df.DID = mf.DID
                                              )
                                        )
                                    )
                                  OR(  
                                        ISNULL(p.Estatus,'') <> 'CANCELADO' 
                                    AND df.DID = mf.DID
                                    )
                                  )
              WHERE 
                aux.Cuenta <> 'SHCP' -- Los movs de SCHP no deberian generar Poliza hoy en dia.
              AND mf.DModulo = 'CONT'
              AND mf.DID = ISNULL(ISNULL(p.ContID,c.ContID),g.ContID)
              ORDER BY
                df.DID DESC
             ) pol

  WHERE
    r.Mayor = 'CXP'
  AND aux.Ejercicio = @Ejercicio 
  AND aux.Periodo = @Periodo
  AND ISNULL(at.Clave,'') NOT IN ('CXP.SCH','CXP.SD')
  AND aux.Modulo = 'CXP'

  UNION
  -- Reevaluaciones de Movimientos del mes
  SELECT 
    AuxID = NULL,
    Fecha = CAST(p.FechaEmision AS DATE),
    p.Sucursal,
    p.Proveedor,
    ProvNombre = REPLACE(REPLACE(REPLACE(Prov.Nombre,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    ProvCta = REPLACE(REPLACE(REPLACE(Prov.Cuenta,CHAR(13),''),CHAR(10),''),CHAR(9),''),
    Modulo = 'CXP',
    ModuloID = p.ID,
    p.Mov,
    p.MovID,
    p.ProveedorMoneda,
    p.ProveedorTipoCambio,
    Cargo = 0,
    Abono = 0,
    Neto = 0,
    CargoMN = ISNULL(impCargoAbono.Cargo,0),
    AbonoMN = ISNULL(impCargoAbono.Abono,0),
    NetoMN = ISNULL(impCargoAbono.Cargo,0) -ISNULL( impCargoAbono.Abono,0),
    FluctuacionMN  = 0,
    Totalmn = ISNULL(impCargoAbono.Cargo,0) -ISNULL( impCargoAbono.Abono,0),
    d.Aplica,
    d.AplicaID,
    EsCancelacion = 0,
    OrigenModulo =  ' ',
    OrigenModuloID = ' ',
    OrigenMov = '',
    OrigenMovID = '',
    OrigenPoliza = '',
    PolizaID = p.ContID,
    PolizaMov = ISNULL(pol.Mov,''),
    PolizaMovId = ISNULL(pol.MovID,'')
  FROM 
    Cxp p
  JOIN Prov ON prov.Proveedor = p.Proveedor
  JOIN CxpD d ON d.Id = p.ID
  JOIN movtipo t ON t.Modulo = 'CXP'
                AND t.Mov  = p.Mov 
  -- Cargos Abonos ( para mantener el formato del auxiliar )
  CROSS APPLY (
                SELECT 
                  Cargo = CASE
                            WHEN ISNULL(d.Importe,0) >= 0 THEN
                              ISNULL(d.Importe,0)
                            ELSE 
                              0
                          END,
                  Abono = CASE
                            WHEN ISNULL(d.Importe,0) < 0 THEN
                              ABS(ISNULL(d.Importe,0))
                            ELSE 
                              0
                          END
                ) impCargoAbono
  LEFT JOIN Cont pol ON pol.ID = p.ContID
  WHERE 
    t.Clave = 'CXP.RE'
  AND p.Estatus = 'CONCLUIDO'
  AND p.Ejercicio = @Ejercicio
  AND p.Periodo = @Periodo
END