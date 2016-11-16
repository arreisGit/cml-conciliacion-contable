SET ANSI_NULLS, ANSI_WARNINGS ON;

GO 

/*=============================================
  Created by:    Enrique Sierra Gtez
  Creation Date: 2016-10-10


  Description: Desglosa las Diferencias Cambiarias 
              de los Movimientos en Cxc y CxP.
 
  Example: SELECT * 
            FROM  CUP_v_CxDiferenciasCambiarias
            WHERE Modulo = 'CXP'
            AND ModuloID = 108192

=============================================*/


IF EXISTS(SELECT * FROM sysobjects WHERE name='CUP_v_CxDiferenciasCambiarias')
	DROP VIEW CUP_v_CxDiferenciasCambiarias
GO
CREATE VIEW CUP_v_CxDiferenciasCambiarias
AS

SELECT -- Cobros CXC
  c.Ejercicio,
  c.Periodo,
  Modulo = 'CXC',
  ModuloID = c.ID,
  Mov = c.Mov,
  MovId = c.MoviD,
  c.Estatus,
  Fecha = c.FechaEmision,
  Documento = d.Aplica,
  DocumentoID = d.AplicaID,
  DocumentoTipo = dt.Clave,
  Moneda = c.ClienteMoneda,
  Importe = importe_aplica.Importe,
  TipoCambioRev  = tcRev.TipoCambio,
  TipoCambioPago        = c.ClienteTipoCambio,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = dt.Factor,
  Diferencia_Cambiaria_MN = ROUND((  
                                    ISNULL(importes_calculo.ImporteMNTCAplica,0)
                                  - ISNULL(importes_calculo.ImporteMNTCRev,0)
                                  ) * dt.Factor,4,1)
FROM
  Cxc c 
JOIN Movtipo t ON t.Modulo = 'CXC'
              AND t.Mov = c.Mov 
JOIN cxcD d ON d.id = c.id
JOIN Movtipo dt ON dt.Modulo = 'CXC'
                AND dt.Mov = d.Aplica
JOIN cxc doc ON doc.Mov = d.Aplica
            AND doc.Movid = d.AplicaID
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   ROUND((c.TipoCambio / c.ClienteTipoCambio),4,1),
                Importe =  ROUND(d.Importe * (c.TipoCambio / c.ClienteTipoCambio),4,1)
            ) importe_aplica 
-- Origen 
OUTER APPLY(SELECT TOP 1
              v.FechaEmision, 
              v.TipoCambio
            FROM 
              Venta v 
            WHERE 
              'VTAS' = doc.OrigenTipo
            AND v.Mov = doc.Origen
            AND v.MovID = doc.OrigenID
            ) origen
-- Ultima Rev
OUTER APPLY ( SELECT TOP 1  
                ur.ID ,
                TipoCambio = ur.ClienteTipoCambio
              FROM 
                  Cxc ur 
              JOIN CxcD urD ON  urD.Id = ur.ID
              JOIN Movtipo urt ON urt.Modulo = 'CXC'
                              AND urt.Mov =   ur.Mov
              WHERE
                urt.Clave = 'CXC.RE'
              AND ur.Estatus = 'CONCLUIDO'
              AND ur.FechaEmision < c.FechaRegistro 
              AND urD.Aplica = d.Aplica
              AND urD.AplicaID = d.AplicaID  
              ORDER BY 
                ur.ID DESC ) ultRev
-- Tipo de Cambio Historico
OUTER APPLY(
            SELECT 
              TipoCambio = ISNULL(ultRev.TipoCambio,ISNULL(origen.TipoCambio,doc.TipoCambio))
            ) tcRev
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tcRev.TipoCambio,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  c.ClienteTipoCambio,4,1)
            ) importes_calculo

WHERE 
    c.Estatus IN ('CONCLUIDO','CANCELADO')
AND c.ClienteMoneda <> 'Pesos'
AND t.clave IN ('CXC.C','CXC.ANC')
AND ISNULL(d.Importe,0) <> 0
AND d.Aplica NOT IN ('Redondeo','Saldo a Favor')
AND dt.Clave <> 'CXC.NC'

UNION -- Aplicaciones CXC

SELECT
  c.Ejercicio,
  c.Periodo,
  Modulo = 'CXC',
  c.ID,
  Mov = c.Mov,
  MovId = c.MovID,
  c.Estatus,
  Fecha = c.FechaEmision,
  Documento = c.MovAplica,
  DocumentoID = c.MovAplicaID,
  DocumentoTipo = mt.Clave,
  Moneda = c.Moneda,
  Importe = importe_aplica.Importe,
  TipoCambioRev  = tcRev.TipoCambio,
  TipoCambioPago  = c.TipoCambio,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = mt.Factor,
  DiferenciaMN = Round((  
                          ISNULL(importes_calculo.ImporteMNTCAplica,0)
                        - ISNULL(importes_calculo.ImporteMNTCRev,0)
                        ) * mt.Factor,4,1)
FROM
  Cxc c 
JOIN Movtipo t ON t.Modulo = 'CXC'
              AND t.Mov = c.Mov 
JOIN cxc doc ON doc.Mov = c.MovAplica
            AND doc.Movid = c.MovAplicaID
JOIN Movtipo mt ON mt.Modulo = 'CXC'
                AND mt.Mov = c.MovAplica
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   1,
                Importe =  ROUND(ISNULL(c.Importe,0) 
                                + ISNULL(c.Impuestos,0) 
                                - ISNULL(c.Retencion,0),4,1)
            ) importe_aplica 
-- Origen
OUTER APPLY(SELECT TOP 1
              v.FechaEmision, 
              v.TipoCambio
            FROM 
              Venta v 
            WHERE 
              'VTAS' = doc.OrigenTipo
            AND v.Mov = doc.Origen
            AND v.MovID = doc.OrigenID
            ) origen
-- Ultima Rev
OUTER APPLY ( SELECT TOP 1  
                ur.ID ,
                TipoCambio = ur.ClienteTipoCambio
              FROM 
                  Cxc ur 
              JOIN CxcD urD ON  urD.Id = ur.ID
              JOIN Movtipo urt ON urt.Modulo = 'CXC'
                              AND urt.Mov =   ur.Mov
              WHERE
                urt.Clave = 'CXC.RE'
              AND ur.Estatus = 'CONCLUIDO'
              AND ur.FechaEmision < c.FechaRegistro 
              AND urD.Aplica = c.MovAplica
              AND urD.AplicaID = c.MovAplicaID
              ORDER BY 
                ur.ID DESC ) ultRev
-- Tipo de Cambio Historico
OUTER APPLY(
            SELECT 
              TipoCambio = ISNULL(ultRev.TipoCambio,ISNULL(origen.TipoCambio,doc.TipoCambio))
            ) tcRev
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tcRev.TipoCambio,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  c.TipoCambio,4,1)
            ) importes_calculo
WHERE 
   c.Estatus IN ('CONCLUIDO','CANCELADO')
AND c.Moneda <> 'Pesos'
AND t.clave IN ('CXC.C','CXC.ANC')
AND ISNULL(c.Importe,0) <> 0

UNION -- Amortizacion Facturas Anticipo en Facturas de Venta

SELECT
  v.Ejercicio,
  v.Periodo,
  Modulo = 'VTAS',
  v.ID,
  v.Mov,
  v.MovID,
  v.Estatus,
  Fecha = v.FechaEmision,
  Documento = doc.Mov,
  DocumentoID = doc.MovID,
  DocumentoTipo = mt.Clave,
  Moneda = v.Moneda,
  Importe = vfa.Importe,
  TipoCambioRev  = tcRev.TipoCambio,
  TipoCambioPago  = v.TipoCambio,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = mt.Factor,
  DiferenciaMN = Round((  
                          ISNULL(importes_calculo.ImporteMNTCAplica,0)
                        - ISNULL(importes_calculo.ImporteMNTCRev,0)
                        ) * mt.Factor,4,1)
FROM
  Venta v 
JOIN Movtipo t ON t.Modulo = 'VTAS'
              AND t.Mov = v.Mov  
JOIN VentaFacturaAnticipo vfa ON vfa.ID = v.ID
JOIN cxc doc ON doc.ID = vfa.CxcID
JOIN Movtipo mt ON mt.Modulo = 'CXC'
               AND mt.Mov = doc.Mov
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   1,
                Importe =  ROUND(vfa.Importe,4,1)
            ) importe_aplica 
-- Ultima Rev
OUTER APPLY ( SELECT TOP 1  
                ur.ID ,
                TipoCambio = ur.ClienteTipoCambio
              FROM 
                  Cxc ur 
              JOIN CxcD urD ON  urD.Id = ur.ID
              JOIN Movtipo urt ON urt.Modulo = 'CXC'
                              AND urt.Mov =   ur.Mov
              WHERE
                urt.Clave = 'CXC.RE'
              AND ur.Estatus = 'CONCLUIDO'
              AND ur.FechaEmision < doc.FechaRegistro 
              AND urD.Aplica = doc.Mov
              AND urD.AplicaID = doc.MovID
              ORDER BY 
                ur.ID DESC ) ultRev
-- Tipo de Cambio Historico
OUTER APPLY(
            SELECT 
              TipoCambio = ISNULL(ultRev.TipoCambio,doc.TipoCambio)
            ) tcRev
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tcRev.TipoCambio,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  v.TipoCambio,4,1)
            ) importes_calculo
WHERE 
   v.Estatus IN ('CONCLUIDO','CANCELADO')
AND v.Moneda <> 'Pesos'
AND t.clave = 'VTAS.F'
AND ISNULL(v.Importe,0) <> 0

UNION -- Amortizacion Facturas Anticipo en Devoluciones Factura Anticicpo

SELECT
  c.Ejercicio,
  c.Periodo,
  Modulo = 'CXC',
  c.ID,
  c.Mov,
  c.MovID,
  c.Estatus,
  Fecha = c.FechaEmision,
  Documento = doc.Mov,
  DocumentoID = doc.MovID,
  DocumentoTipo = mt.Clave,
  Moneda = c.Moneda,
  Importe = cfa.Importe,
  TipoCambioRev  = tcRev.TipoCambio,
  TipoCambioPago  = c.TipoCambio,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = mt.Factor,
  DiferenciaMN = Round((  
                          ISNULL(importes_calculo.ImporteMNTCAplica,0)
                        - ISNULL(importes_calculo.ImporteMNTCRev,0)
                        ) * mt.Factor,4,1)
FROM
  Cxc c 
JOIN Movtipo t ON t.Modulo = 'CXC'
              AND t.Mov = c.Mov  
JOIN CxcFacturaAnticipo cfa ON cfa.ID = c.ID
JOIN cxc doc ON doc.ID = cfa.CxcID
JOIN Movtipo mt ON mt.Modulo = 'CXC'
               AND mt.Mov = doc.Mov
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   1,
                Importe =  ROUND(cfa.Importe,4,1)
            ) importe_aplica 
-- Ultima Rev
OUTER APPLY ( SELECT TOP 1  
                ur.ID ,
                TipoCambio = ur.ClienteTipoCambio
              FROM 
                  Cxc ur 
              JOIN CxcD urD ON  urD.Id = ur.ID
              JOIN Movtipo urt ON urt.Modulo = 'CXC'
                              AND urt.Mov =   ur.Mov
              WHERE
                urt.Clave = 'CXC.RE'
              AND ur.Estatus = 'CONCLUIDO'
              AND ur.FechaEmision < doc.FechaRegistro 
              AND urD.Aplica = doc.Mov
              AND urD.AplicaID = doc.MovID
              ORDER BY 
                ur.ID DESC ) ultRev
-- Tipo de Cambio Historico
OUTER APPLY(
            SELECT 
              TipoCambio = ISNULL(ultRev.TipoCambio,doc.TipoCambio)
            ) tcRev
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tcRev.TipoCambio,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  c.TipoCambio,4,1)
            ) importes_calculo
WHERE 
   c.Estatus IN ('CONCLUIDO','CANCELADO')
AND c.Moneda <> 'Pesos'
AND t.clave = 'CXC.DFA'
AND ISNULL(c.Importe,0) <> 0

UNION -- Pagos Cxp

SELECT
  p.Ejercicio,
  p.Periodo,
  Modulo = 'CXP',
  ModuloID = p.ID,
  Mov = p.Mov,
  MovId = p.MovID,
  p.Estatus,
  Fecha = p.FechaEmision,
  Documento = d.Aplica,
  DocumentoID = d.AplicaID,
  DocumentoTipo = dt.Clave,
  Moneda = p.ProveedorMoneda,
  Importe = importe_aplica.Importe,
  TipoCambioReevaluado  = tcRev.TipoCambio,
  TipoCambioPago  = p.ProveedorTipoCambio,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = -1,
  DiferenciaMN = ROUND((  
                          ISNULL(importes_calculo.ImporteMNTCAplica,0)
                        - ISNULL(importes_calculo.ImporteMNTCRev,0)
                       ) * -1,4,1)
FROM
  Cxp p 
JOIN Movtipo t ON t.Modulo = 'Cxp'
              AND t.Mov = p.Mov 
JOIN CxpD d ON d.id = p.id
JOIN Movtipo dt ON dt.Modulo = 'Cxp'
                AND dt.Mov = d.Aplica

JOIN Cxp doc ON doc.Mov = d.Aplica
               AND doc.Movid = d.AplicaID
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   ROUND((p.TipoCambio / p.ProveedorTipoCambio),4,1),
                Importe =  ROUND(d.Importe * (p.TipoCambio / p.ProveedorTipoCambio),4,1)
            ) importe_aplica 
-- Origen 
OUTER APPLY(
            SELECT TOP 1
              c.FechaEmision, 
              c.TipoCambio
            FROM 
              Compra c 
            WHERE 
              'COMS' = doc.OrigenTipo
            AND c.Mov = doc.Origen
            AND c.MovID = doc.OrigenID
            UNION 
            SELECT TOP 1
              g.FechaEmision, 
              g.TipoCambio
            FROM 
              Gasto g 
            WHERE 
              'GAS' = doc.OrigenTipo
            AND g.Mov = doc.Origen
            AND g.MovID = doc.OrigenID
            ) origen
-- Ultima Rev
OUTER APPLY ( SELECT TOP 1  
                ur.ID ,
                TipoCambio = ur.ProveedorTipoCambio
              FROM 
                  Cxp ur 
              JOIN CxpD urD ON  urD.Id = ur.ID
              JOIN Movtipo urt ON urt.Modulo = 'CXP'
                              AND urt.Mov =   ur.Mov
              WHERE
                urt.Clave = 'CXP.RE'
              AND ur.Estatus = 'CONCLUIDO'
              AND ur.FechaEmision < p.FechaRegistro 
              AND urD.Aplica = d.Aplica
              AND urD.AplicaID = d.AplicaID
              ORDER BY 
                ur.ID DESC ) ultRev
-- Tipo de Cambio Historico
OUTER APPLY(
            SELECT 
              TipoCambio = ISNULL(ultRev.TipoCambio,ISNULL(origen.TipoCambio,doc.TipoCambio))
            ) tcRev
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tcRev.TipoCambio,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  p.ProveedorTipoCambio,4,1)
            ) importes_calculo
WHERE 
    p.Estatus IN ('CONCLUIDO','CANCELADO')
AND p.ProveedorMoneda <> 'Pesos'
AND t.clave IN ('CXP.P','CXP.ANC')
AND ISNULL(d.Importe,0) <> 0
AND d.Aplica NOT IN ('Redondeo','Saldo a Favor')
AND dt.Clave <> 'CXP.NC'

UNION -- Aplicaciones Pagos

SELECT
  p.Ejercicio,
  p.Periodo,
  Modulo = 'CXP',
  ModuloID = p.ID,
  Mov = p.Mov,
  MovID = p.MovID,
  p.Estatus,
  Fecha = p.FechaEmision,
  Documento = p.MovAplica,
  DocumentoID = p.MovAplicaID,
  DocumentoTipo = mt.Clave,
  Moneda = p.Moneda,
  Importe         = importe_aplica.Importe,
  TipoCambioReevaluado  = tcRev.TipoCambio,
  TipoCambioPago  = p.TipoCambio,
  ImporteMN_al_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_al_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = 1,
  DiferenciaMN = ROUND((  
                        ISNULL(importes_calculo.ImporteMNTCAplica,0)
                      - ISNULL(importes_calculo.ImporteMNTCRev,0)
                        ) * 1,4,1)
FROM
  CXP p
JOIN Movtipo t ON t.Modulo = 'CXP'
              AND t.Mov = p.Mov 
JOIN CXP doc ON doc.Mov = p.MovAplica
            AND doc.Movid = p.MovAplicaID
JOIN Movtipo mt ON mt.Modulo = 'CXP'
                AND mt.Mov = p.MovAplica
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   1,
                Importe =  ROUND(ISNULL(p.Importe,0) 
                                + ISNULL(p.Impuestos,0) 
                                - ISNULL(p.Retencion,0),4,1)
            ) importe_aplica 
-- Origen 
OUTER APPLY(
            SELECT TOP 1
              c.FechaEmision, 
              c.TipoCambio
            FROM 
              Compra c 
            WHERE 
              'COMS' = doc.OrigenTipo
            AND c.Mov = doc.Origen
            AND c.MovID = doc.OrigenID
            UNION 
            SELECT TOP 1
              g.FechaEmision, 
              g.TipoCambio
            FROM 
              Gasto g 
            WHERE 
              'GAS' = doc.OrigenTipo
            AND g.Mov = doc.Origen
            AND g.MovID = doc.OrigenID
            ) origen-- Ultima Rev
OUTER APPLY ( SELECT TOP 1  
                ur.ID ,
                TipoCambio = ur.ProveedorTipoCambio
              FROM 
                  Cxp ur 
              JOIN CxpD urD ON  urD.Id = ur.ID
              JOIN Movtipo urt ON urt.Modulo = 'CXP'
                              AND urt.Mov =   ur.Mov
              WHERE
                urt.Clave = 'CXP.RE'
              AND ur.Estatus = 'CONCLUIDO'
              AND ur.FechaEmision < p.FechaRegistro 
              AND urD.Aplica = p.MovAplica
              AND urD.AplicaID = p.MovAplicaID
              ORDER BY 
                ur.ID DESC ) ultRev
-- Tipo de Cambio Historico
OUTER APPLY(
            SELECT 
              TipoCambio = ISNULL(ultRev.TipoCambio,ISNULL(origen.TipoCambio,doc.TipoCambio))
            ) tcRev
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tcRev.TipoCambio,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  p.ProveedorTipoCambio,4,1)
            ) importes_calculo
WHERE 
   p.Estatus IN('CONCLUIDO','CANCELADO')
AND p.Moneda <> 'Pesos'
AND t.clave IN ('CXP.P','CXP.ANC')
AND ISNULL(p.Importe,0) <> 0
 