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

SELECT -- Cobros CXC y Ajustes.
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
  TipoCambioOriginal = tc_calc.TipoCambioOrigen,
  TipoCambioRev  = tc_calc.TipoCambioRev,
  TipoCambioPago        = c.ClienteTipoCambio,
  ImporteMN_TC_Origen = importes_calculo.ImporteMNTCOrigen,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = dt.Factor,
  Diferencia_Cambiaria_MN = ROUND((  
                                    ISNULL(importes_calculo.ImporteMNTCAplica,0)
                                  - ISNULL(importes_calculo.ImporteMNTCRev,0)
                                  ) * dt.Factor,4,1),
  Diferencia_Cambiaria_TCOrigen_MN = ROUND((  
                                            ISNULL(importes_calculo.ImporteMNTCAplica,0)
                                          - ISNULL(importes_calculo.ImporteMNTCOrigen,0)
                                          ) * dt.Factor,4,1),
  importes_calculo.IVAFiscal
FROM
  Cxc c 
JOIN Movtipo t ON t.Modulo = 'CXC'
              AND t.Mov = c.Mov 
JOIN cxcD d ON d.id = c.id
JOIN Movtipo dt ON dt.Modulo = 'CXC'
                AND dt.Mov = d.Aplica
JOIN cxc doc ON doc.Mov = d.Aplica
            AND doc.Movid = d.AplicaID
-- MovFlujo Origen
OUTER APPLY(
              SELECT TOP 1
                mf.OModulo,
                mf.OID
              FROM 
                MovFlujo mf 
              WHERE 
                mf.DModulo = 'CXC'
              AND mf.DID = doc.ID
              AND mf.OModulo = doc.OrigenTipo
              AND mf.OMov = doc.Origen
              AND mf.OMovID = doc.OrigenID
           ) mfOrigen
-- Primer Tc
OUTER APPLY(
            SELECT TOP 1 
                first_aux.TipoCambio
            FROM 
              Auxiliar first_aux 
            JOIN Rama fr ON fr.Rama = first_aux.Rama 
            WHERE 
              fr.Mayor = 'CXC'
            AND first_aux.Modulo = 'CXC'
            AND first_aux.ModuloID = doc.ID
            ORDER BY 
              first_aux.ID ASC
           ) primer_tc
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   ROUND((c.TipoCambio / c.ClienteTipoCambio),4,1),
                Importe =  ROUND(d.Importe * (c.TipoCambio / c.ClienteTipoCambio),4,1)
            ) importe_aplica 
-- Datos del doc en Modulo Origen
OUTER APPLY(SELECT TOP 1
              v.FechaEmision, 
              v.TipoCambio
            FROM 
              Venta v 
            WHERE 
               'VTAS'  = mfOrigen.OModulo 
            AND v.ID = mfOrigen.OID
            ) movEnOrigen
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
-- Tipos de Cambio Origen y el Ultimo Reevaluado.
OUTER APPLY(
            SELECT 
              TipoCambioOrigen = ISNULL
                                (
                                  movEnOrigen.TipoCambio,
                                  ISNULL
                                  (
                                    primer_tc.TipoCambio,
                                    doc.ClienteTipoCambio 
                                  )
                                ),
              TipoCambioRev = ISNULL(ultRev.TipoCambio,ISNULL(movEnOrigen.TipoCambio,doc.TipoCambio))
            ) tc_Calc
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCOrigen = ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioOrigen,4,1),
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioRev,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  c.ClienteTipoCambio,4,1),
              IVAFiscal = CASE
                            WHEN ISNULL(dt.Clave,'') = 'CXC.NC'
                              AND dt.Mov = 'Saldos Cte' THEN
                                0.137931034482759 -- Factor de 16/116
                            ELSE
                              ISNULL(doc.IVAFiscal,0)
                           END
            ) importes_calculo

WHERE 
    c.Estatus IN ('CONCLUIDO','CANCELADO')
AND c.ClienteMoneda <> 'Pesos'
AND t.clave IN ('CXC.C','CXC.ANC','CXC.AJM')
AND ISNULL(d.Importe,0) <> 0
AND d.Aplica NOT IN ('Redondeo','Saldo a Favor')
AND NOT (    
             t.Clave <> 'CXC.AJM'
         AND dt.Clave = 'CXC.NC'
        )

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
  TipoCambioOriginal = tc_calc.TipoCambioOrigen,
  TipoCambioRev  = tc_calc.TipoCambioRev,
  TipoCambioPago  = c.TipoCambio,
  ImporteMN_TC_Origen = importes_calculo.ImporteMNTCOrigen,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = mt.Factor,
  DiferenciaMN = Round((  
                          ISNULL(importes_calculo.ImporteMNTCAplica,0)
                        - ISNULL(importes_calculo.ImporteMNTCRev,0)
                        ) * mt.Factor,4,1),
  Diferencia_Cambiaria_TCOrigen_MN = ROUND((  
                                            ISNULL(importes_calculo.ImporteMNTCAplica,0)
                                          - ISNULL(importes_calculo.ImporteMNTCOrigen,0)
                                          ) * mt.Factor,4,1),
  importes_calculo.IVAFiscal
FROM
  Cxc c 
JOIN Movtipo t ON t.Modulo = 'CXC'
              AND t.Mov = c.Mov 
JOIN cxc doc ON doc.Mov = c.MovAplica
            AND doc.Movid = c.MovAplicaID
JOIN Movtipo mt ON mt.Modulo = 'CXC'
                AND mt.Mov = c.MovAplica
-- MovFlujo Origen
OUTER APPLY(
              SELECT TOP 1
                mf.OModulo,
                mf.OID
              FROM 
                MovFlujo mf 
              WHERE 
                mf.DModulo = 'CXC'
              AND mf.DID = doc.ID
              AND mf.OModulo = doc.OrigenTipo
              AND mf.OMov = doc.Origen
              AND mf.OMovID = doc.OrigenID
           ) mfOrigen
-- Primer Tc
OUTER APPLY(
            SELECT TOP 1 
              first_aux.TipoCambio
            FROM 
              Auxiliar first_aux 
            JOIN Rama fr ON fr.Rama = first_aux.Rama 
            WHERE 
              fr.Mayor = 'CXC'
            AND first_aux.Modulo = 'CXC'
            AND first_aux.ModuloID = doc.ID
            ORDER BY 
              first_aux.ID ASC
           ) primer_tc
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   1,
                Importe =  ROUND(ISNULL(c.Importe,0) 
                                + ISNULL(c.Impuestos,0) 
                                - ISNULL(c.Retencion,0),4,1)
            ) importe_aplica 
-- Datos del doc en Modulo Origen
OUTER APPLY(SELECT TOP 1
              v.FechaEmision, 
              v.TipoCambio
            FROM 
              Venta v 
            WHERE 
               'VTAS'  = mfOrigen.OModulo 
            AND v.ID = mfOrigen.OID
            ) movEnOrigen
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
-- Tipos de Cambio Origen y el Ultimo Reevaluado.
OUTER APPLY(
            SELECT 
              TipoCambioOrigen = ISNULL
                                (
                                  movEnOrigen.TipoCambio,
                                  ISNULL
                                  (
                                    primer_tc.TipoCambio,
                                    doc.ClienteTipoCambio 
                                  )
                                ),
              TipoCambioRev = ISNULL(ultRev.TipoCambio,ISNULL(movEnOrigen.TipoCambio,doc.TipoCambio))
            ) tc_Calc
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCOrigen = ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioOrigen,4,1),
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioRev,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  c.TipoCambio,4,1),
              IVAFiscal = CASE
                            WHEN ISNULL(mt.Clave,'') = 'CXC.NC'
                              AND mt.Mov = 'Saldos Cte' THEN
                                0.137931034482759 -- Factor de 16/116
                            ELSE
                              ISNULL(doc.IVAFiscal,0)
                           END
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
  TipoCambioOriginal = tc_Calc.TipoCambioOrigen,
  TipoCambioRev  = tc_Calc.TipoCambioRev,
  TipoCambioPago  = v.TipoCambio,
  ImporteMN_TC_Origen = importes_calculo.ImporteMNTCOrigen,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = mt.Factor,
  DiferenciaMN = Round((  
                           ISNULL(importes_calculo.ImporteMNTCRev,0)
                         - ISNULL(importes_calculo.ImporteMNTCAplica,0)
                        ) * mt.Factor,4,1),
  Diferencia_Cambiaria_TCOrigen_MN = ROUND((  
                                            ISNULL(importes_calculo.ImporteMNTCAplica,0)
                                          - ISNULL(importes_calculo.ImporteMNTCOrigen,0)
                                          ) * mt.Factor,4,1),
  doc.IVAFiscal
FROM
  Venta v 
JOIN Movtipo t ON t.Modulo = 'VTAS'
              AND t.Mov = v.Mov  
JOIN VentaFacturaAnticipo vfa ON vfa.ID = v.ID
JOIN cxc doc ON doc.ID = vfa.CxcID
JOIN Movtipo mt ON mt.Modulo = 'CXC'
               AND mt.Mov = doc.Mov
-- Primer Tc
OUTER APPLY(
            SELECT TOP 1 
              first_aux.TipoCambio
            FROM 
              Auxiliar first_aux 
            JOIN Rama fr ON fr.Rama = first_aux.Rama 
            WHERE 
              fr.Mayor = 'CXC'
            AND first_aux.Modulo = 'CXC'
            AND first_aux.ModuloID = doc.ID
            ORDER BY 
              first_aux.ID ASC
           ) primer_tc
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
-- Tipos de Cambio Origen y el Ultimo Reevaluado.
OUTER APPLY(
            SELECT 
              TipoCambioOrigen = ISNULL
                                 (
                                   primer_tc.TipoCambio,
                                   doc.ClienteTipoCambio 
                                 ),
              TipoCambioRev = ISNULL(ultRev.TipoCambio, doc.TipoCambio)
            ) tc_Calc
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCOrigen = ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioOrigen,4,1),
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioRev,4,1),
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
  TipoCambioOriginal = tc_Calc.TipoCambioOrigen,
  TipoCambioRev  = tc_Calc.TipoCambioRev,
  TipoCambioPago  = c.TipoCambio,
  ImporteMN_TC_Origen = importes_calculo.ImporteMNTCOrigen,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = mt.Factor,
  DiferenciaMN = Round((  
                          ISNULL(importes_calculo.ImporteMNTCRev,0)
                        - ISNULL(importes_calculo.ImporteMNTCAplica,0)
                        ) * mt.Factor,4,1),
  Diferencia_Cambiaria_TCOrigen_MN = ROUND((  
                                            ISNULL(importes_calculo.ImporteMNTCAplica,0)
                                          - ISNULL(importes_calculo.ImporteMNTCOrigen,0)
                                          ) * mt.Factor,4,1),
  doc.IVAFiscal
FROM
  Cxc c 
JOIN Movtipo t ON t.Modulo = 'CXC'
              AND t.Mov = c.Mov  
JOIN CxcFacturaAnticipo cfa ON cfa.ID = c.ID
JOIN cxc doc ON doc.ID = cfa.CxcID
JOIN Movtipo mt ON mt.Modulo = 'CXC'
               AND mt.Mov = doc.Mov
-- Primer Tc
OUTER APPLY(
            SELECT TOP 1 
              first_aux.TipoCambio
            FROM 
              Auxiliar first_aux 
            JOIN Rama fr ON fr.Rama = first_aux.Rama 
            WHERE 
              fr.Mayor = 'CXC'
            AND first_aux.Modulo = 'CXC'
            AND first_aux.ModuloID = doc.ID
            ORDER BY 
              first_aux.ID ASC
           ) primer_tc
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
-- Tipos de Cambio Origen y el Ultimo Reevaluado.
OUTER APPLY(
            SELECT 
              TipoCambioOrigen = ISNULL
                                 (
                                   primer_tc.TipoCambio,
                                   doc.ClienteTipoCambio 
                                 ),
              TipoCambioRev = ISNULL(ultRev.TipoCambio, doc.TipoCambio)
            ) tc_Calc
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCOrigen = ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioOrigen,4,1),
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioRev,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  c.TipoCambio,4,1)
            ) importes_calculo
WHERE 
   c.Estatus IN ('CONCLUIDO','CANCELADO')
AND c.Moneda <> 'Pesos'
AND t.clave = 'CXC.DFA'
AND ISNULL(c.Importe,0) <> 0

UNION -- Pagos y Ajustes Cxp 

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
  TipoCambioOriginal = tc_calc.TipoCambioOrigen,
  TipoCambioReevaluado  = tc_calc.TipoCambioRev,
  TipoCambioPago  = p.ProveedorTipoCambio,
  ImporteMN_TC_Origen = importes_calculo.ImporteMNTCOrigen,
  ImporteMN_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = -1,
  DiferenciaMN = ROUND((  
                          ISNULL(importes_calculo.ImporteMNTCAplica,0)
                        - ISNULL(importes_calculo.ImporteMNTCRev,0)
                       ) * calc.FactorDiff,4,1),
  Diferencia_Cambiaria_TCOrigen_MN = ROUND
                                    (
                                        (  
                                          ISNULL(importes_calculo.ImporteMNTCAplica,0)
                                        - ISNULL(importes_calculo.ImporteMNTCOrigen,0)
                                        ) 
                                      * calc.FactorDiff,
                                      4, 1
                                   ),
  doc.IVAFiscal
FROM
  Cxp p 
JOIN Movtipo t ON t.Modulo = 'CXP'
              AND t.Mov = p.Mov 
JOIN CxpD d ON d.id = p.id
JOIN Movtipo dt ON dt.Modulo = 'CXP'
                AND dt.Mov = d.Aplica
JOIN Cxp doc ON doc.Mov = d.Aplica
               AND doc.Movid = d.AplicaID
-- MovFlujo Origen
OUTER APPLY(
              SELECT TOP 1
                mf.OModulo,
                mf.OID
              FROM 
                MovFlujo mf 
              WHERE 
                mf.DModulo = 'CXC'
              AND mf.DID = doc.ID
              AND mf.OModulo = doc.OrigenTipo
              AND mf.OMov = doc.Origen
              AND mf.OMovID = doc.OrigenID
            ) mfOrigen
-- Primer Tc
OUTER APPLY(
            SELECT TOP 1 
                first_aux.TipoCambio
            FROM 
              Auxiliar first_aux 
            JOIN Rama fr ON fr.Rama = first_aux.Rama 
            WHERE 
              fr.Mayor = 'CXP'
            AND first_aux.Modulo = 'CXP'
            AND first_aux.ModuloID = doc.ID
            ORDER BY 
              first_aux.ID ASC
           ) primer_tc           
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   ROUND((p.TipoCambio / p.ProveedorTipoCambio),4,1),
                Importe =  ROUND(d.Importe * (p.TipoCambio / p.ProveedorTipoCambio),4,1)
            ) importe_aplica 
-- Datos del doc en Modulo Origen
OUTER APPLY(
            SELECT TOP 1
              coms.FechaEmision, 
              coms.TipoCambio
            FROM 
              Compra coms 
            WHERE 
               'COMS'   = mfOrigen.OModulo 
            AND coms.ID = mfOrigen.OID
            UNION
            SELECT TOP 1
              gas.FechaEmision, 
              gas.TipoCambio
            FROM 
              Gasto gas 
            WHERE 
               'GAS'   = mfOrigen.OModulo 
            AND gas.ID = mfOrigen.OID
            ) movEnOrigen
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
-- Tipos de Cambio Origen y el Ultimo Reevaluado.
OUTER APPLY(
            SELECT 
              TipoCambioOrigen = ISNULL
                                (
                                  movEnOrigen.TipoCambio,
                                  ISNULL
                                  (
                                    primer_tc.TipoCambio,
                                    doc.ProveedorTipoCambio
                                  )
                                ),
              TipoCambioRev = ISNULL
                              (
                                ultRev.TipoCambio,
                                ISNULL
                                (
                                  movEnOrigen.TipoCambio,
                                  doc.TipoCambio
                                )
                              )
            ) tc_Calc
-- Campos Calculados
CROSS APPLY( 
            SELECT
              FactorDiff = CASE t.Clave
                            WHEN 'CXP.DC' THEN 
                              1
                            ELSE 
                              -1
                           END  
            ) calc
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCOrigen = ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioOrigen,4,1),
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioRev,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  p.TipoCambio,4,1)
            ) importes_calculo
WHERE 
    p.Estatus IN ('CONCLUIDO','CANCELADO')
AND p.ProveedorMoneda <> 'Pesos'
AND t.clave IN ('CXP.P','CXP.ANC','CXP.DC','CXP.AJM')
AND ISNULL(d.Importe,0) <> 0
AND d.Aplica NOT IN ('Redondeo','Saldo a Favor')
AND NOT(   t.Clave IN ('CXP.P','CXP.ANC')
        AND dt.Clave = 'CXP.NC')

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
  TipoCambioOriginal = tc_calc.TipoCambioOrigen,
  TipoCambioReevaluado  = tc_calc.TipoCambioRev,
  TipoCambioPago  = p.TipoCambio,
  ImporteMN_TC_Origen = importes_calculo.ImporteMNTCOrigen,
  ImporteMN_al_TC_Rev = importes_calculo.ImporteMNTCRev,
  ImporteMN_al_TC_Pago = importes_calculo.ImporteMNTCAplica,
  Factor = 1,
  DiferenciaMN = ROUND(  
                        ISNULL(importes_calculo.ImporteMNTCAplica,0)
                      - ISNULL(importes_calculo.ImporteMNTCRev,0)
                      , 4, 1),
  Diferencia_Cambiaria_TCOrigen_MN= ROUND(  
                                            ISNULL(importes_calculo.ImporteMNTCAplica,0)
                                          - ISNULL(importes_calculo.ImporteMNTCOrigen,0)
                                          , 4, 1),
  doc.IVAFiscal
FROM
  CXP p
JOIN Movtipo t ON t.Modulo = 'CXP'
              AND t.Mov = p.Mov 
JOIN CXP doc ON doc.Mov = p.MovAplica
            AND doc.Movid = p.MovAplicaID
JOIN Movtipo mt ON mt.Modulo = 'CXP'
                AND mt.Mov = p.MovAplica
-- MovFlujo Origen
OUTER APPLY(
              SELECT TOP 1
                mf.OModulo,
                mf.OID
              FROM 
                MovFlujo mf 
              WHERE 
                mf.DModulo = 'CXC'
              AND mf.DID = doc.ID
              AND mf.OModulo = doc.OrigenTipo
              AND mf.OMov = doc.Origen
              AND mf.OMovID = doc.OrigenID
            ) mfOrigen
-- Primer Tc
OUTER APPLY(
            SELECT TOP 1 
                first_aux.TipoCambio
            FROM 
              Auxiliar first_aux 
            JOIN Rama fr ON fr.Rama = first_aux.Rama 
            WHERE 
              fr.Mayor = 'CXP'
            AND first_aux.Modulo = 'CXP'
            AND first_aux.ModuloID = doc.ID
            ORDER BY 
              first_aux.ID ASC
           ) primer_tc   
-- Importe Aplica 
CROSS APPLY( SELECT   
                FactorTC =   1,
                Importe =  ROUND
                           (
                              ISNULL(p.Importe,0) 
                            + ISNULL(p.Impuestos,0) 
                            - ISNULL(p.Retencion,0)
                           ,4,1)
            ) importe_aplica 
-- Datos del doc en Modulo Origen
OUTER APPLY(
            SELECT TOP 1
              coms.FechaEmision, 
              coms.TipoCambio
            FROM 
              Compra coms 
            WHERE 
               'COMS'   = mfOrigen.OModulo 
            AND coms.ID = mfOrigen.OID
            UNION
            SELECT TOP 1
              gas.FechaEmision, 
              gas.TipoCambio
            FROM 
              Gasto gas 
            WHERE 
               'GAS'   = mfOrigen.OModulo 
            AND gas.ID = mfOrigen.OID
            ) movEnOrigen
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
              AND urD.Aplica = p.MovAplica
              AND urD.AplicaID = p.MovAplicaID
              ORDER BY 
                ur.ID DESC ) ultRev
-- Tipos de Cambio Origen y el Ultimo Reevaluado.
OUTER APPLY(
            SELECT              
              TipoCambioOrigen = ISNULL
                                (
                                  movEnOrigen.TipoCambio,
                                  ISNULL
                                  (
                                    primer_tc.TipoCambio,
                                    doc.ProveedorTipoCambio
                                  )
                                ),
              TipoCambioRev = ISNULL
                              (
                                ultRev.TipoCambio,
                                ISNULL
                                (
                                  movEnOrigen.TipoCambio,
                                  doc.TipoCambio
                                )
                              )
            ) tc_Calc
-- Importes MN para el calculo
CROSS APPLY( 
            SELECT
              ImporteMNTCOrigen = ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioOrigen,4,1),
              ImporteMNTCRev =  ROUND(ISNULL(importe_aplica.Importe,0) *  tc_Calc.TipoCambioRev,4,1),
              ImporteMNTCAplica =  ROUND(ISNULL(importe_aplica.Importe,0) *  p.ProveedorTipoCambio,4,1)
            ) importes_calculo
WHERE 
   p.Estatus IN('CONCLUIDO','CANCELADO')
AND p.Moneda <> 'Pesos'
AND t.clave IN ('CXP.P','CXP.ANC')
AND ISNULL(p.Importe,0) <> 0