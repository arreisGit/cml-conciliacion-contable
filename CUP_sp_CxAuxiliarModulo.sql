DECLARE 
  @Ejercicio INT = 2016,
  @Periodo INT = 9,
  @Modulo CHAR(5)  = 'CXP'

BEGIN

  -- Detalle Auxiliar
  SELECT   
    aux.ID,
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
    Neto = ISNULL(aux.Cargo,0) -ISNULL( aux.Abono,0),
    CargoMN = ROUND(ISNULL(aux.Cargo,0) * aux.TipoCambio,2,1),
    AbonoMN = ROUND(ISNULL(aux.Abono,0) * aux.TipoCambio,2,1),
    NetoMN =  ROUND((ISNULL(aux.Cargo,0) -ISNULL( aux.Abono,0)) * aux.TipoCambio,2,1),
    FluctuacionMN  = ISNULL(fc.Diferencia_Cambiaria_MN,0) * -1,
    ReevaluacionMN  = ISNULL(revsMes.Importe,0),
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
  -- Fluctuacion Cambiaria
  LEFT JOIN CUP_v_CxDiferenciasCambiarias fc ON fc.Modulo = aux.Modulo
                                            AND fc.ModuloID = aux.ModuloId
                                            AND fc.Documento = aux.Aplica
                                            AND fc.DocumentoID = aux.AplicaID
  -- Reevaluaciones del MES 
  OUTER APPLY ( SELECT
                    Importe = SUM(ISNULL(revsD.Importe,0))              
                 FROM 
                    Cxp revs 
                JOIN CxpD revsD ON  revsD.Id = revs.ID
                JOIN Movtipo revsT ON revst.Modulo = 'CXP'
                                  AND revst.Mov =   revs.Mov
                WHERE
                  revsT.Clave = 'CXP.RE'
                AND revs.Estatus = 'CONCLUIDO'
                AND revs.Ejercicio = @Ejercicio
                AND revs.Periodo = @Periodo
                AND revsD.Aplica = aux.Mov
                AND revsD.AplicaID = aux.MovId  
               ) revsMes
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
                mf.DModulo = 'CONT'
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
  ORDER BY 
    aux.Modulo,
    t.Clave,
    Aux.Aplica,
    at.Clave
END