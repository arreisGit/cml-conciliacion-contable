SET ANSI_NULLS, ANSI_WARNINGS ON;

GO 

/*=============================================
 Created by:    Enrique Sierra Gtez
 Creation Date: 2016-11-10

 Description: Regresa el auxiliar de 
 Saldos Cxc.

 Example: SELECT TOP 10 * 
          FROM  CUP_v_AuxiliarCxc
-- ============================================*/


IF EXISTS(SELECT * FROM sysobjects WHERE name='CUP_v_AuxiliarCxc')
	DROP VIEW CUP_v_AuxiliarCxc
GO
CREATE VIEW CUP_v_AuxiliarCxc
AS
SELECT
  a.Rama,
  AuxID = a.ID,
  a.Sucursal,
  a.Cuenta,
  calc.Mov,
  calc.MovId,
  calc.Modulo,
  calc.ModuloID,
  a.Moneda,
  a.TipoCambio,
  a.Fecha,
  Cargo = ISNULL(a.Cargo,0),
  Abono = ISNULL(a.Abono,0),
  calc.Neto,
  CargoMN = ROUND(ISNULL(a.Cargo,0) * a.TipoCambio,4,1),
  AbonoMN = ROUND(ISNULL(a.Abono,0) * a.TipoCambio,4,1),
  NetoMN =  ROUND(ISNULL(calc.Neto,0) * a.TipoCambio,4,1),
  calc.FluctuacionMN,
  TotalMN = ROUND(  
                  (calc.Neto * a.TipoCambio)
                + (calc.FluctuacionMN)
            ,4,1),
  a.EsCancelacion,
  --AplicaID = aplica.ID,
  calc.Aplica,
  calc.AplicaID,
  OrigenModulo = ISNULL(c.OrigenTipo,''),
  OrigenModuloID = ISNULL(CAST(v.ID AS VARCHAR),''),
  OrigenMov = ISNULL(c.Origen,''),
  OrigenMovID = ISNULL(c.OrigenID,'')
FROM 
	Auxiliar a
JOIN Rama r on r.Rama = a.Rama
JOIN Movtipo t ON t.Modulo = a.Modulo
              AND t.Mov  = a.Mov  
LEFT JOIN Cxc c ON c.ID = a.ModuloID
LEFT JOIN Venta v ON 'VTAS' = c.OrigenTipo
                  AND v.Mov = c.Origen
                  AND v.MovID = c.OrigenID
                  AND v.Estatus IN ('PENDIENTE','CONCLUIDO')
LEFT JOIN cxc aplica ON aplica.Mov = a.Aplica
                    AND aplica.Movid = a.AplicaID
LEFT JOIN Movtipo at ON at.Modulo = 'CXC'
                    AND at.Mov = a.Aplica
-- Factores
CROSS APPLY(SELECT
              FactorCanc  = CASE ISNULL(a.EsCancelacion,0) 
                              WHEN 1 THEN
                                -1
                              ELSE 
                                1
                            END) f 
-- Fluctuacion Cambiaria
LEFT JOIN CUP_v_CxDiferenciasCambiarias fc ON fc.Modulo = a.Modulo
                                          AND fc.ModuloID = a.ModuloId
                                          AND fc.Documento = a.Aplica
                                          AND fc.DocumentoID = a.AplicaID
-- Campos Calculados
CROSS APPLY ( SELECT
                Mov = CASE 
                        WHEN ISNULL(t.Clave,'') = 'CXC.NC'
                        AND  a.Mov = 'Saldos Cte' THEN
                          ISNULL(c.Origen,a.Mov)
                        ELSE
                          a.Mov
                      END,
                MovId = CASE
                          WHEN ISNULL(t.Clave,'') = 'CXC.NC'
                          AND  a.Mov = 'Saldos Cte' THEN
                            ISNULL(c.OrigenID,a.MovID)
                          ELSE
                            a.MovID
                        END, 
                Modulo = CASE
                            WHEN ISNULL(t.Clave,'') = 'CXC.NC'
                            AND  a.Mov = 'Saldos Cte' THEN
                              'CXC'
                            ELSE
                              a.Modulo
                          END,
                ModuloID = CASE 
                              WHEN ISNULL(t.Clave,'') = 'CXC.NC'
                              AND  a.Mov = 'Saldos Cte' THEN
                                1
                              ELSE
                                a.ModuloID
                            END,
                Aplica =  CASE
                            WHEN ISNULL(t.Clave,'') = 'CXC.NC'
                            AND  a.Mov = 'Saldos Cte' THEN
                                a.Mov
                            ELSE
                                a.Aplica
                          END,
                AplicaId = CASE
                                WHEN ISNULL(t.Clave,'') = 'CXC.NC'
                                AND  a.Mov = 'Saldos Cte' THEN
                                  a.MovID
                                ELSE
                                  a.AplicaID
                              END, 
                Neto = ISNULL(a.Cargo,0) - ISNULL( a.Abono,0),
                FluctuacionMN =  ROUND(ISNULL(fc.Diferencia_Cambiaria_MN,0) * ISNULL(f.FactorCanc,1),4,1)
            ) Calc
WHERE 
	r.Mayor = 'CXC'
AND a.Modulo = 'CXC'
AND t.CLave NOT IN ('CXC.SCH','CXC.SD')

UNION  -- Kike Sierra: 2016-11-09: Saldo al corte facturas anticipo

SELECT
  a.Rama,
  a.AuxID,
  a.Sucursal,
  a.Cuenta,
  Mov      = a.Mov,
  MovID    = a.MovID,
  Modulo   = a.Modulo,
  ModuloID = a.ModuloID,
  a.Moneda,
  a.TipoCambio,
  a.Fecha,
  Cargo = ISNULL(a.Cargo,0),
  Abono = ISNULL(a.Abono,0),
  calc.Neto,
  CargoMN = ROUND(ISNULL(a.Cargo,0) * a.TipoCambio,4,1),
  AbonoMN = ROUND(ISNULL(a.Abono,0) * a.TipoCambio,4,1),
  NetoMN =  ROUND(ISNULL(calc.Neto,0) * a.TipoCambio,4,1),
  calc.FluctuacionMN,
  TotalMN = ROUND(  
                  (calc.Neto * a.TipoCambio)
                + (calc.FluctuacionMN)
            ,4,1),
  a.EsCancelacion,
  Aplica = a.AplicaMov,
  AplicaID = a.AplicaMovID,
  OrigenModulo = '',
  OrigenModuloID = '',
  OrigenMov = '',
  OrigenMovID = ''
FROM 
  CUP_v_CxcAuxiliarAnticipos a
-- Factores
CROSS APPLY(SELECT
              FactorCanc  = CASE ISNULL(a.EsCancelacion,0) 
                              WHEN 1 THEN
                                -1
                              ELSE 
                                1
                            END) f 
-- Fluctuacion Cambiaria
LEFT JOIN CUP_v_CxDiferenciasCambiarias fc ON fc.Modulo = a.Modulo
                                          AND fc.ModuloID = a.ModuloId
                                          AND fc.Documento = a.AplicaMov
                                          AND fc.DocumentoID = a.AplicaMovID
-- Campos Calculados
CROSS APPLY ( SELECT   
                Neto = ISNULL(a.Cargo,0) - ISNULL( a.Abono,0),
                FluctuacionMN =  ROUND(ISNULL(fc.Diferencia_Cambiaria_MN,0) * ISNULL(f.FactorCanc,1),4,1)
            ) Calc

  
UNION -- Reevaluaciones del Mes
  
-- Reevaluaciones de Movimientos del mes
SELECT
  Rama = 'REV',
  AuxID = NULL,
  c.Sucursal,
  Cuenta = c.Cliente,
  c.Mov,
  c.MovID,
  Modulo = 'CXC',
  ModuloID = c.ID,
  Moneda = c.ClienteMoneda,
  TipoCambio = c.ClienteTipoCambio,
  Fecha = CAST(c.FechaEmision AS DATE),
    Cargo = 0,
  Abono = 0,
  Neto = 0,
  CargoMN = ISNULL(impCargoAbono.Cargo,0),
  AbonoMN = ISNULL(impCargoAbono.Abono,0),
  NetoMN = ISNULL(impCargoAbono.Cargo,0) -ISNULL( impCargoAbono.Abono,0),
  FluctuacionMN  = 0,
  TotalMN = ISNULL(impCargoAbono.Cargo,0) -ISNULL( impCargoAbono.Abono,0),
  EsCancelacion = 0,
  --AplicaID = doc.ID,
  d.Aplica,
  d.AplicaID,
  OrigenModulo =  ' ',
  OrigenModuloID = ' ',
  OrigenMov = '',
  OrigenMovID = ''
FROM 
  Cxc c
JOIN Cte ON Cte.Cliente = c.Cliente
JOIN CxcD d ON d.Id = c.ID
JOIN movtipo t ON t.Modulo = 'CXC'
              AND t.Mov  = c.Mov 
LEFT JOIN cxc doc ON doc.Mov = d.Aplica
                  AND doc.MovID = d.AplicaID
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
LEFT JOIN Cont pol ON pol.ID = c.ContID
WHERE 
  t.Clave = 'CXC.RE'
AND c.Estatus = 'CONCLUIDO'