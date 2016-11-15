SET ANSI_NULLS, ANSI_WARNINGS ON;

GO 

/*=============================================
 Created by:    Enrique Sierra Gtez
 Creation Date: 2016-11-10r

 Description: Regresa el auxiliar de 
 Saldos Cxc.

 Example: SELECT * 
          FROM  CUP_v_AuxiliarCxc
          WHERE 
            Ejercicio = 2016
          AND Periodo = 10
            
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
  a.Mov,
  a.MovId,
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
  calc.Neto,
  CargoMN = ROUND(ISNULL(a.Cargo,0) * a.TipoCambio,4,1),
  AbonoMN = ROUND(ISNULL(a.Abono,0) * a.TipoCambio,4,1),
  NetoMN =  ROUND(ISNULL(calc.Neto,0) * a.TipoCambio,4,1),
  a.EsCancelacion,
  a.Aplica,
  a.AplicaID,
  AplicaClave = at.Clave,
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
-- Campos Calculados
CROSS APPLY ( SELECT
                Neto = ISNULL(a.Cargo,0) - ISNULL( a.Abono,0)
            ) Calc
WHERE 
	r.Mayor = 'CXC'
AND a.Modulo = 'CXC'
AND t.Clave NOT IN ('CXC.SCH','CXC.SD')

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
  MovClave = a.MovClave,
  a.Moneda,
  a.TipoCambio,
  a.Ejercicio,
  a.Periodo,
  a.Fecha,
  Cargo = ISNULL(a.Cargo,0),
  Abono = ISNULL(a.Abono,0),
  calc.Neto,
  CargoMN = ROUND(ISNULL(a.Cargo,0) * a.TipoCambio,4,1),
  AbonoMN = ROUND(ISNULL(a.Abono,0) * a.TipoCambio,4,1),
  NetoMN =  ROUND(ISNULL(calc.Neto,0) * a.TipoCambio,4,1),
  a.EsCancelacion,
  Aplica = a.AplicaMov,
  AplicaID = a.AplicaMovID,
  a.AplicaClave,
  OrigenModulo = '',
  OrigenModuloID = '',
  OrigenMov = '',
  OrigenMovID = ''
FROM 
  CUP_v_CxcAuxiliarAnticipos a
-- Campos Calculados
CROSS APPLY ( SELECT   
                Neto = ISNULL(a.Cargo,0) - ISNULL( a.Abono,0)
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
    MovClave = t.Clave,
    Moneda = c.ClienteMoneda,
    TipoCambio = c.ClienteTipoCambio,
    c.Ejercicio,
    c.Periodo,
    Fecha = CAST(c.FechaEmision AS DATE),
      Cargo = 0,
    Abono = 0,
    Neto = 0,
    CargoMN = ISNULL(impCargoAbono.Cargo,0),
    AbonoMN = ISNULL(impCargoAbono.Abono,0),
    NetoMN = ISNULL(impCargoAbono.Cargo,0) -ISNULL( impCargoAbono.Abono,0),
    EsCancelacion = 0,
    --AplicaID = doc.ID,
    d.Aplica,
    d.AplicaID,
    AplicaClave = at.Clave,
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
  LEFT JOIN movtipo at ON at.Modulo = 'CXC'
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
  LEFT JOIN Cont pol ON pol.ID = c.ContID
  WHERE 
    t.Clave = 'CXC.RE'
  AND c.Estatus = 'CONCLUIDO'