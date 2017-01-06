SET ANSI_NULLS, ANSI_WARNINGS ON;

GO 

/*=============================================
 Created by:    Enrique Sierra Gtez
 Creation Date: 2016-11-07

 Description: Emula un auxiliar sobre 
 la rama CANT , para poder reconstruir 
 la antigüedad de saldos de las facturas
 anticipo.
 
 Example: SELECT * 
          FROM  CUP_v_CxcAuxiliarAnticipos
          WHERE
              Aplica = 
          AND AplicaID = 
-- ============================================*/


IF EXISTS(SELECT * FROM sysobjects WHERE name='CUP_v_CxcAuxiliarAnticipos')
	DROP VIEW CUP_v_CxcAuxiliarAnticipos
GO
CREATE VIEW CUP_v_CxcAuxiliarAnticipos
AS

-- Provision Facturas Anticipo
SELECT 
  AuxID = aux.ID,
  aux.Empresa,
  aux.Sucursal,
  aux.Rama,
  aux.Cuenta,
  aux.Mov,
  aux.MovId,
  aux.Modulo,
  aux.ModuloID,
  MovClave = t.Clave,
  aux.Moneda,
  aux.TipoCambio,
  aux.Ejercicio,
  aux.Periodo,
  aux.Fecha,
  calc.Cargo,
  calc.Abono,
  aux.EsCancelacion,
  AplicaID    = aux.ModuloID,
  AplicaMov   = aux.Aplica,
  AplicaMovId = aux.AplicaID,
  AplicaClave = t.Clave,
  IVAFiscal = ISNULL(doc.IVAFiscal,0),
  FactorRetencion = CASE
                      WHEN ISNULL(doc.IVAFiscal,0) = 0 
                        OR ISNULL(doc.Impuestos,0) = 0 THEN
                        0
                      ELSE
                        ISNULL(doc.Retencion,0) / ISNULL(doc.Impuestos,0)
                    END
FROM 
  Auxiliar aux 
JOIN Rama r ON r.Rama = aux.Rama
JOIN Movtipo t ON t.Modulo =  aux.Modulo
              AND t.Mov    =  aux.Mov
-- Documento
LEFT JOIN Cxc doc ON doc.Mov = aux.Aplica
                 AND doc.MovID = aux.AplicaID   
-- CALC 
OUTER APPLY( SELECT 
                Cargo  = aux.Abono,
                Abono  = aux.Cargo
            ) calc
WHERE 
  r.Mayor = 'CANT'
AND t.Clave = 'CXC.FA'

UNION -- Aplicacion desde Ventas ( en Facturas )

SELECT 
  AuxID = aux.ID,
  aux.Empresa,
  aux.Sucursal,
  aux.Rama,
  aux.Cuenta,
  aux.Mov,
  aux.Movid,
  aux.Modulo,
  aux.ModuloID,
  MovClave = t.Clave,
  aux.Moneda,
  aux.TipoCambio,
  aux.Ejercicio,
  aux.Periodo,
  aux.Fecha,
  calc.Cargo,
  calc.Abono,
  aux.EsCancelacion,
  AplicaID = vfa.CxcID,
  AplicaMov =  c.Mov,
  AplicaMovID = c.MovID,
  AplicaClave = at.Clave,
  IVAFiscal = ISNULL(c.IVAFiscal,0),
  FactorRetencion = CASE
                      WHEN ISNULL(c.IVAFiscal,0) = 0 
                        OR ISNULL(c.Impuestos,0) = 0 THEN
                        0
                      ELSE
                        ISNULL(c.Retencion,0) / ISNULL(c.Impuestos,0)
                    END
FROM 
  Auxiliar aux 
JOIN Rama r ON r.Rama = aux.Rama
JOIN VentaFacturaAnticipo vfa ON  vfa.ID = aux.ModuloID
JOIN Venta v ON v.ID = vfa.ID 
JOIN movtipo t ON t.Modulo = 'VTAS'
              AND t.Mov = v.Mov
-- Factura Anticipo
JOIN Cxc c ON c.ID = vfa.CxcID
JOIN movtipo at ON at.Modulo = 'CXC'
               AND at.Mov = c.Mov
--Factores
CROSS APPLY(SELECT
              FactorCanc  = CASE
                              WHEN aux.EsCancelacion =  1 THEN 
                                -1
                              ELSE 
                                1
                            END
            ) f
-- CALC 
OUTER APPLY( SELECT 
                Cargo  = vfa.Importe  * f.FactorCanc,
                Abono  = NULL
            ) calc
WHERE 
  r.Mayor = 'CANT'
AND aux.Modulo = 'VTAS'

UNION -- Aplicacion desde Cxc ( Devoluciones )

SELECT 
  AuxID = aux.ID,
  aux.Empresa,
  aux.Sucursal,
  aux.Rama,
  aux.Cuenta,
  aux.Mov,
  aux.Movid,
  aux.Modulo,
  aux.ModuloID,
  MovClave = t.Clave,
  aux.Moneda,
  aux.TipoCambio,
  aux.Ejercicio,
  aux.Periodo,
  aux.Fecha,
  calc.Cargo,
  calc.Abono,
  aux.EsCancelacion,
  AplicaID = cfa.CxcID,
  AplicaMov = c.Mov,
  AplicaMovID = c.MovID,
  AplicaClave = at.CLave,
  IVAFiscal = ISNULL(c.IVAFiscal,0),
  FactorRetencion = CASE
                      WHEN ISNULL(c.IVAFiscal,0) = 0 
                        OR ISNULL(c.Impuestos,0) = 0 THEN
                        0
                      ELSE
                        ISNULL(c.Retencion,0) / ISNULL(c.Impuestos,0)
                    END
FROM 
  Auxiliar aux 
JOIN Rama r ON r.Rama = aux.Rama
JOIN Movtipo t ON t.Modulo =  aux.Modulo
              AND t.Mov    =  aux.Mov
JOIN CxcFacturaAnticipo cfa ON  cfa.ID = aux.ModuloID
-- Factura Anticipo
JOIN Cxc c ON c.ID = cfa.CxcID
JOIN Movtipo at ON at.Modulo =  'CXC'
               AND at.Mov    =  c.Mov
--Factores
CROSS APPLY(SELECT
              FactorCanc  = CASE
                              WHEN aux.EsCancelacion =  1 THEN 
                                -1
                              ELSE 
                                1
                            END
            ) f
-- CALC 
OUTER APPLY( SELECT 
                Cargo  = cfa.Importe  * f.FactorCanc,
                Abono  = NULL
            ) calc
WHERE 
  r.Mayor = 'CANT'
AND aux.Modulo = 'CXC'
AND t.Clave <> 'CXC.FA'