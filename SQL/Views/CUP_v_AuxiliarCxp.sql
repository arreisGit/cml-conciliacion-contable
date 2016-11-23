SET ANSI_NULLS, ANSI_WARNINGS ON;

GO 

/*=============================================
 Created by:    Enrique Sierra Gtez
 Creation Date: 2016-11-17

 Description: Regresa el auxiliar de 
 Saldos Cxp.

 Example: SELECT * 
          FROM  CUP_v_AuxiliarCxp
          WHERE 
            Ejercicio = 2016
          AND Periodo = 10       
-- ============================================*/


IF EXISTS(SELECT * FROM sysobjects WHERE name='CUP_v_AuxiliarCxp')
	DROP VIEW CUP_v_AuxiliarCxp
GO
CREATE VIEW CUP_v_AuxiliarCxp
AS
-- Detalle Auxiliar
SELECT
  a.Rama,
  AuxID  = a.ID,
  a.Sucursal,
  a.Cuenta,
  a.Mov,
  a.MovID,
  a.Modulo,
  a.ModuloID,
  MovClave = t.Clave,
  a.Moneda,
  a.TipoCambio,
  a.Ejercicio,
  a.Periodo,
  a.Fecha,
  Cargo = ISNULL(a.Cargo,0),
  Abono = ISNULL(a.Abono,0),
  Neto = calc.Neto,
  CargoMN = ROUND(ISNULL(a.Cargo,0) * a.TipoCambio,4,1),
  AbonoMN = ROUND(ISNULL(a.Abono,0) * a.TipoCambio,4,1),
  NetoMN =  ROUND(ISNULL(calc.Neto,0) * a.TipoCambio,4,1),
  a.EsCancelacion,
  a.Aplica,
  a.AplicaID,
  AplicaClave = at.Clave,
  OrigenModulo = ISNULL(p.OrigenTipo,''),
  OrigenMov = ISNULL(p.Origen,''),
  OrigenMovID = ISNULL(p.OrigenID,''),
  IVAFiscal =  ISNULL(doc.IvaFiscal,0)
FROM
  Auxiliar a 
JOIN Rama r ON r.Rama = a.Rama
JOIN Prov ON prov.Proveedor = a.Cuenta
JOIN Movtipo t ON t.Modulo = a.Modulo 
              AND  t.Mov  = a.Mov
LEFT JOIN MovTipo at ON at.Modulo = a.Modulo
                    AnD at.Mov = a.Aplica
LEFT JOIN Cxp p ON 'CXP' = a.Modulo
                AND p.ID = a.ModuloID  
-- Documento
JOIN Cxp doc ON doc.Mov = a.Aplica
            AND doc.MovID = a.AplicaID                   
-- Factor Canceclacion
CROSS APPLY(SELECT
              Factor  = CASE ISNULL(a.EsCancelacion,0) 
                          WHEN 1 THEN
                            -1
                          ELSE 
                            1
                        END) fctorCanc 
-- Campos Calculados
CROSS APPLY ( SELECT   
                Neto = ISNULL(a.Cargo,0) - ISNULL( a.Abono,0)
            ) Calc
WHERE
  r.Mayor = 'CXP'
AND ISNULL(at.Clave,'') NOT IN ('CXP.SCH','CXP.SD')
AND a.Modulo = 'CXP'

UNION

-- Reevaluaciones de Movimientos del mes
SELECT
  Rama = 'REV',
  AuxID = NULL,
  p.Sucursal,
  Cuenta = p.Proveedor,
  p.Mov,
  p.MovID,
  Modulo = 'CXP',
  ModuloID = p.ID,
  MovClave = t.Clave,
  Moneda = p.ProveedorMoneda,
  TipoCambio = p.ProveedorTipoCambio,
  p.Ejercicio,
  p.Periodo,
  Fecha = CAST(p.FechaEmision AS DATE),
  Cargo = 0,
  Abono = 0,
  Neto = 0,
  CargoMN = ISNULL(impCargoAbono.Cargo,0),
  AbonoMN = ISNULL(impCargoAbono.Abono,0),
  NetoMN = ISNULL(impCargoAbono.Cargo,0) -ISNULL( impCargoAbono.Abono,0),
  EsCancelacion = 0,
  d.Aplica,
  d.AplicaID,
  AplicaClave = at.Clave,
  OrigenModulo =  '',
  OrigenMov = '',
  OrigenMovID = '',
  IVAFiscal  = ISNULL(doc.IvaFiscal,0)
FROM 
  Cxp p
JOIN Prov ON prov.Proveedor = p.Proveedor
JOIN CxpD d ON d.Id = p.ID
JOIN movtipo t ON t.Modulo = 'CXP'
              AND t.Mov  = p.Mov 
-- Documento
LEFT JOIN Cxp doc ON doc.Mov = d.Aplica
            AND doc.MovID = d.AplicaID    
LEFT JOIN movtipo at ON at.Modulo = 'CXP'
                      AND at.Mov = d.Aplica
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
WHERE 
  t.Clave = 'CXP.RE'
AND p.Estatus = 'CONCLUIDO'