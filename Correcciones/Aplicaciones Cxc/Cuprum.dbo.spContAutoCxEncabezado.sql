SET ANSI_NULLS, QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE dbo.spContAutoCxEncabezado
@Empresa		varchar(5),
@Sucursal		int,
@Modulo			varchar(5),
@ID			int,
@MovTipo		varchar(20),
@Orden			int,
@Debe			varchar(20),
@Haber			varchar(20),
@Cta			varchar(20),
@ContUso		varchar(20),
@ContUso2		varchar(20),
@ContUso3		varchar(20),
@Concepto		varchar(50),
@Diferencia		money,
@DiferenciaIVA		money,
@DiferenciaIEPS		money,
@CxTipoCambio		float,
@ContactoTipoCambio	float,
@CxImporteTotalMN	money,
@CxImporteAplicaMN	money,
@CxIVAMN		money,
@CxIVAAplicaMN		money,
@CxIEPSMN		money,
@CxIEPSAplicaMN		money,
@CxPicosMN		money,
@ContactoSubTipo	varchar(20),
@ContAutoContactoEsp	varchar(50),
@Contacto		varchar(10),
@ContactoAplica		varchar(10),
@CtaDinero		varchar(10),
@CtaDineroDestino	varchar(10),
@Ok			int		OUTPUT,
@OkRef			varchar(255)	OUTPUT
WITH ENCRYPTION
AS BEGIN
DECLARE
@Monto		money,
@ContactoEspecifico	varchar(10),
@Agente		varchar(10),
@Personal		varchar(10)
IF @Modulo = 'CXC'
SELECT @Agente = Agente, @Personal = PersonalCobrador
FROM Cxc
WHERE ID = @ID
SELECT @ContactoEspecifico = dbo.fnContactoEspecifico(@ContAutoContactoEsp, @Contacto, @ContactoAplica, NULL, @Agente, @Personal, @CtaDinero, @CtaDineroDestino, NULL, NULL, NULL)
IF @Modulo = 'CXC'
BEGIN
IF @Debe   = 'IMPORTE'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Importe*TipoCambio 	FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'IMPORTE'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Importe*TipoCambio 	FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'IMPUESTOS' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Impuestos*TipoCambio    	FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'IMPUESTOS' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Impuestos*TipoCambio    	FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'RETENCIONES' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Retencion, 0)+ISNULL(Retencion2, 0)+ISNULL(Retencion3, 0))*TipoCambio    	FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'RETENCIONES' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Retencion, 0)+ISNULL(Retencion2, 0)+ISNULL(Retencion3, 0))*TipoCambio    	FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'IMPORTE TOTAL'        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'IMPORTE TOTAL'        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'IVA FISCAL'        	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IVAFiscal  FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'IVA FISCAL'        	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IVAFiscal  FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'IEPS FISCAL'        	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IEPSFiscal FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'IEPS FISCAL'        	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IEPSFiscal FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'IMPORTE S/FISCAL'     INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio)-ISNULL((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IVAFiscal, 0.0)-ISNULL((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IEPSFiscal, 0.0) FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'IMPORTE S/FISCAL'    	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio)-ISNULL((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IVAFiscal, 0.0)-ISNULL((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IEPSFiscal, 0.0) FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'SALDO A FAVOR'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Debe  ELSE
IF @Haber  = 'SALDO A FAVOR'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Haber ELSE
IF @Debe   = 'REDONDEO'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Debe  ELSE
IF @Haber  = 'REDONDEO'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Haber ELSE
IF @Debe   = 'ANTICIPOS ACUMULADOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Debe  ELSE
IF @Haber  = 'ANTICIPOS ACUMULADOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Haber ELSE
IF @Debe   = 'UTILIDAD'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.Importe*e.TipoCambio) 	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND d.Importe>0 ELSE
IF @Haber  = 'UTILIDAD'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.Importe*e.TipoCambio) 	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND d.Importe>0 ELSE
IF @Debe   = 'PERDIDA'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(-d.Importe*e.TipoCambio) 	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND d.Importe<0 ELSE
IF @Haber  = 'PERDIDA'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(-d.Importe*e.TipoCambio) 	FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID AND d.Importe<0 ELSE
IF @Debe  IN ('DIFERENCIA IVA', 'UTILIDAD IVA', 'PERDIDA IVA', 'DIFERENCIA IEPS', 'UTILIDAD IEPS', 'PERDIDA IEPS') OR
@Haber IN ('DIFERENCIA IVA', 'UTILIDAD IVA', 'PERDIDA IVA', 'DIFERENCIA IEPS', 'UTILIDAD IEPS', 'PERDIDA IEPS')
BEGIN
SELECT @DiferenciaIVA = SUM(d.Importe*a.IVAFiscal),
@DiferenciaIEPS = SUM(d.Importe*a.IEPSFiscal)
FROM CxcD d
JOIN CxcAplica a  ON a.Mov = d.Aplica AND a.MovID = d.AplicaID AND a.Empresa = @Empresa
WHERE d.ID = @ID
IF @Debe  = 'DIFERENCIA IVA'  INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA)  ELSE
IF @Haber = 'DIFERENCIA IVA'  INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA)  ELSE
IF @Debe  = 'UTILIDAD IVA'    AND @DiferenciaIVA  > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA) ELSE
IF @Haber = 'UTILIDAD IVA'    AND @DiferenciaIVA  > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA) ELSE
IF @Debe  = 'PERDIDA IVA'     AND @DiferenciaIVA  < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIVA) ELSE
IF @Haber = 'PERDIDA IVA'     AND @DiferenciaIVA  < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIVA) ELSE
IF @Debe  = 'DIFERENCIA IEPS' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Haber = 'DIFERENCIA IEPS' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Debe  = 'UTILIDAD IEPS'   AND @DiferenciaIEPS > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Haber = 'UTILIDAD IEPS'   AND @DiferenciaIEPS > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Debe  = 'PERDIDA IEPS'    AND @DiferenciaIEPS < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIEPS) ELSE
IF @Haber = 'PERDIDA IEPS'    AND @DiferenciaIEPS < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIEPS)
END ELSE
IF @Debe   = 'INTERESES'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'INTERESES'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'INTERESES NETOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*(1-(ISNULL(d.InteresesOrdinariosQuita, 0.0)/100.0))*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'INTERESES NETOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*(1-(ISNULL(d.InteresesOrdinariosQuita, 0.0)/100.0))*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'INTERESES QUITA'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*(d.InteresesOrdinariosQuita/100.0)*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'INTERESES QUITA'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*(d.InteresesOrdinariosQuita/100.0)*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'MORATORIOS'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'MORATORIOS'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'MORATORIOS NETOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*(1-(ISNULL(d.InteresesMoratoriosQuita, 0.0)/100.0))*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'MORATORIOS NETOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*(1-(ISNULL(d.InteresesMoratoriosQuita, 0.0)/100.0))*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'MORATORIOS QUITA'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*(d.InteresesMoratoriosQuita/100.0)*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'MORATORIOS QUITA'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*(d.InteresesMoratoriosQuita/100.0)*e.TipoCambio) FROM Cxc e, CxcD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'COMISIONES' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Comisiones*TipoCambio    	FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'COMISIONES' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Comisiones*TipoCambio    	FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'COMISIONES IVA' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ComisionesIVA*TipoCambio    	FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'COMISIONES IVA' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ComisionesIVA*TipoCambio    	FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'TOTAL COMISIONES' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ISNULL(Comisiones, 0.0)+ISNULL(ComisionesIVA, 0.0)*TipoCambio FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'TOTAL COMISIONES' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ISNULL(Comisiones, 0.0)+ISNULL(ComisionesIVA, 0.0)*TipoCambio FROM Cxc WHERE ID = @ID ELSE
IF @Debe   = 'INTERESES ANTICIPADO' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, InteresesAnticipados*TipoCambio FROM Cxc WHERE ID = @ID ELSE
IF @Haber  = 'INTERESES ANTICIPADO' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, InteresesAnticipados*TipoCambio FROM Cxc WHERE ID = @ID ELSE
IF @Debe  IN ('IVA DIF. CAMBIARIA', 'IVA UTI. CAMBIARIA', 'IVA PER. CAMBIARIA', 'IEPS DIF. CAMBIARIA', 'IEPS UTI. CAMBIARIA', 'IEPS PER. CAMBIARIA', 'DIFERENCIA CAMBIARIA', 'UTILIDAD CAMBIARIA', 'PERDIDA CAMBIARIA') OR
@Haber IN ('IVA DIF. CAMBIARIA', 'IVA UTI. CAMBIARIA', 'IVA PER. CAMBIARIA', 'IEPS DIF. CAMBIARIA', 'IEPS UTI. CAMBIARIA', 'IEPS PER. CAMBIARIA', 'DIFERENCIA CAMBIARIA', 'UTILIDAD CAMBIARIA', 'PERDIDA CAMBIARIA')
BEGIN
SELECT @CxImporteTotalMN = (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio, @CxTipoCambio = TipoCambio, @ContactoTipoCambio = ClienteTipoCambio FROM Cxc WHERE ID = @ID
IF @CxTipoCambio <> 1.0 OR @ContactoTipoCambio <> 1.0
BEGIN
SELECT @CxPicosMN = SUM(Importe)*@CxTipoCambio FROM CxcD WHERE ID = @ID AND UPPER(Aplica) IN ('REDONDEO', 'SALDO A FAVOR', 'ANTICIPOS ACUMULADOS')
SELECT @CxImporteTotalMN = @CxImporteTotalMN - ISNULL(@CxPicosMN, 0)
SELECT @CxIVAMN = @CxImporteTotalMN * IVAFiscal, @CxIEPSMN = @CxImporteTotalMN * IEPSFiscal FROM Cxc WHERE ID = @ID
SELECT @CxImporteAplicaMN = SUM(d.Importe/@ContactoTipoCambio*@CxTipoCambio*CASE WHEN @MovTipo = 'CXC.RE' THEN l.TipoCambio ELSE a.TipoCambio END),
@CxIVAAplicaMN = SUM(d.Importe*a.IVAFiscal/@ContactoTipoCambio*@CxTipoCambio*CASE WHEN @MovTipo = 'CXC.RE' THEN l.TipoCambio ELSE a.TipoCambio END),
@CxIEPSAplicaMN = SUM(d.Importe*a.IEPSFiscal/@ContactoTipoCambio*@CxTipoCambio*CASE WHEN @MovTipo = 'CXC.RE' THEN l.TipoCambio ELSE a.TipoCambio END)
FROM CxcD d
JOIN CxcAplica a  ON a.Mov = d.Aplica AND a.MovID = d.AplicaID AND a.Empresa = @Empresa
LEFT OUTER JOIN CxReevaluacionLog l ON l.Modulo = @Modulo AND l.ID = d.ID AND l.Renglon = d.Renglon AND l.RenglonSub = d.RenglonSub
WHERE d.ID = @ID
--SELECT @Diferencia = @CxImporteTotalMN - @CxImporteAplicaMN
SELECT @Diferencia = (SELECT SUM(Diferencia_Cambiaria_MN) FROM CUP_v_CxDiferenciasCambiarias WHERE ModuloID = @ID AND Modulo = 'CXC')
SELECT @DiferenciaIVA = @CxIVAMN - @CxIVAAplicaMN,
@DiferenciaIEPS = @CxIEPSMN - @CxIEPSAplicaMN
IF ISNULL(@Diferencia, 0) <> 0
BEGIN
IF @Debe   = 'DIFERENCIA CAMBIARIA' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Diferencia) ELSE
IF @Haber  = 'DIFERENCIA CAMBIARIA' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Diferencia) ELSE
IF @Debe   = 'UTILIDAD CAMBIARIA'   AND @Diferencia > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)   VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Diferencia) ELSE
IF @Haber  = 'UTILIDAD CAMBIARIA'   AND @Diferencia > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Diferencia) ELSE
IF @Debe   = 'PERDIDA CAMBIARIA'    AND @Diferencia < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)   VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@Diferencia) ELSE
IF @Haber  = 'PERDIDA CAMBIARIA'    AND @Diferencia < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@Diferencia) ELSE
IF @Debe   = 'IVA DIF. CAMBIARIA'  INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA)  ELSE
IF @Haber  = 'IVA DIF. CAMBIARIA'  INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA)  ELSE
IF @Debe   = 'IVA UTI. CAMBIARIA'  AND @DiferenciaIVA > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA) ELSE
IF @Haber  = 'IVA UTI. CAMBIARIA'  AND @DiferenciaIVA > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA) ELSE
IF @Debe   = 'IVA PER. CAMBIARIA'  AND @DiferenciaIVA < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIVA) ELSE
IF @Haber  = 'IVA PER. CAMBIARIA'  AND @DiferenciaIVA < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIVA) ELSE
IF @Debe   = 'IEPS DIF. CAMBIARIA' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Haber  = 'IEPS DIF. CAMBIARIA' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Debe   = 'IEPS UTI. CAMBIARIA' AND @DiferenciaIEPS > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS)  ELSE
IF @Haber  = 'IEPS UTI. CAMBIARIA' AND @DiferenciaIEPS > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS)  ELSE
IF @Debe   = 'IEPS PER. CAMBIARIA' AND @DiferenciaIEPS < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIEPS) ELSE
IF @Haber  = 'IEPS PER. CAMBIARIA' AND @DiferenciaIEPS < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIEPS)
END
END
END
ELSE
BEGIN
IF @Debe IS NOT NULL
BEGIN
EXEC xpContAutoCampoExtra @Modulo, @ID, NULL, NULL, @Debe, @Monto OUTPUT, @Ok OUTPUT, @OkRef OUTPUT
IF @Monto IS NOT NULL
INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Monto*TipoCambio 	FROM Cxc WHERE ID = @ID
END ELSE
IF @Haber IS NOT NULL
BEGIN
EXEC xpContAutoCampoExtra @Modulo, @ID, NULL, NULL, @Haber, @Monto OUTPUT, @Ok OUTPUT, @OkRef OUTPUT
IF @Monto IS NOT NULL
INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Monto*TipoCambio 	FROM Cxc WHERE ID = @ID
END
END
END ELSE
IF @Modulo = 'CXP'
BEGIN
IF @Debe   = 'IMPORTE'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Importe*TipoCambio 	FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'IMPORTE'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Importe*TipoCambio 	FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'IMPUESTOS' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Impuestos*TipoCambio    	FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'IMPUESTOS' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Impuestos*TipoCambio    	FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'RETENCIONES' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Retencion, 0)+ISNULL(Retencion2, 0)+ISNULL(Retencion3, 0))*TipoCambio FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'RETENCIONES' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Retencion, 0)+ISNULL(Retencion2, 0)+ISNULL(Retencion3, 0))*TipoCambio FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'RETENCION ISR' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Retencion*TipoCambio        FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'RETENCION ISR' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Retencion*TipoCambio        FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'RETENCION IVA' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Retencion2*TipoCambio       FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'RETENCION IVA' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Retencion2*TipoCambio       FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'RETENCION 3' 		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Retencion3*TipoCambio       FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'RETENCION 3' 		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Retencion3*TipoCambio       FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'IMPORTE TOTAL'        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0)-ISNULL(Retencion2, 0)-ISNULL(Retencion3, 0))*TipoCambio FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'IMPORTE TOTAL'        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0)-ISNULL(Retencion2, 0)-ISNULL(Retencion3, 0))*TipoCambio FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'IVA FISCAL'        	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0)-ISNULL(Retencion2, 0)-ISNULL(Retencion3, 0))*TipoCambio*IVAFiscal  FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'IVA FISCAL'        	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0)-ISNULL(Retencion2, 0)-ISNULL(Retencion3, 0))*TipoCambio*IVAFiscal  FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'IEPS FISCAL'        	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0)-ISNULL(Retencion2, 0)-ISNULL(Retencion3, 0))*TipoCambio*IEPSFiscal FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'IEPS FISCAL'        	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0)-ISNULL(Retencion2, 0)-ISNULL(Retencion3, 0))*TipoCambio*IEPSFiscal FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'IMPORTE S/FISCAL'    	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio)-ISNULL((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IVAFiscal, 0.0)-ISNULL((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IEPSFiscal, 0.0) FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'IMPORTE S/FISCAL'   	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio)-ISNULL((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IVAFiscal, 0.0)-ISNULL((ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0))*TipoCambio*IEPSFiscal, 0.0) FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'SALDO A FAVOR'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Debe  ELSE
IF @Haber  = 'SALDO A FAVOR'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Haber ELSE
IF @Debe   = 'REDONDEO'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Debe  ELSE
IF @Haber  = 'REDONDEO'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Haber ELSE
IF @Debe   = 'ANTICIPOS ACUMULADOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Debe  ELSE
IF @Haber  = 'ANTICIPOS ACUMULADOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, d.Importe*e.TipoCambio    	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND UPPER(d.Aplica) = @Haber ELSE
IF @Debe   = 'UTILIDAD'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(-d.Importe*e.TipoCambio) 	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND d.Importe<0 ELSE
IF @Haber  = 'UTILIDAD'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(-d.Importe*e.TipoCambio) 	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND d.Importe<0 ELSE
IF @Debe   = 'PERDIDA'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.Importe*e.TipoCambio) 	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND d.Importe>0 ELSE
IF @Haber  = 'PERDIDA'   	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.Importe*e.TipoCambio) 	FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID AND d.Importe>0 ELSE
IF @Debe  IN ('DIFERENCIA IVA', 'UTILIDAD IVA', 'PERDIDA IVA', 'DIFERENCIA IEPS', 'UTILIDAD IEPS', 'PERDIDA IEPS') OR
@Haber IN ('DIFERENCIA IVA', 'UTILIDAD IVA', 'PERDIDA IVA', 'DIFERENCIA IEPS', 'UTILIDAD IEPS', 'PERDIDA IEPS')
BEGIN
SELECT @DiferenciaIVA = SUM(d.Importe*a.IVAFiscal),
@DiferenciaIEPS = SUM(d.Importe*a.IEPSFiscal)
FROM CxpD d
JOIN CxpAplica a  ON a.Mov = d.Aplica AND a.MovID = d.AplicaID AND a.Empresa = @Empresa
WHERE d.ID = @ID
IF @Debe  = 'DIFERENCIA IVA'  INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA)  ELSE
IF @Haber = 'DIFERENCIA IVA'  INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA)  ELSE
IF @Debe  = 'UTILIDAD IVA'    AND @DiferenciaIVA  > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA) ELSE
IF @Haber = 'UTILIDAD IVA'    AND @DiferenciaIVA  > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA) ELSE
IF @Debe  = 'PERDIDA IVA'     AND @DiferenciaIVA  < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIVA) ELSE
IF @Haber = 'PERDIDA IVA'     AND @DiferenciaIVA  < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIVA) ELSE
IF @Debe  = 'DIFERENCIA IEPS' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Haber = 'DIFERENCIA IEPS' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Debe  = 'UTILIDAD IEPS'   AND @DiferenciaIEPS > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Haber = 'UTILIDAD IEPS'   AND @DiferenciaIEPS > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Debe  = 'PERDIDA IEPS'    AND @DiferenciaIEPS < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIEPS) ELSE
IF @Haber = 'PERDIDA IEPS'    AND @DiferenciaIEPS < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIEPS)
END ELSE
IF @Debe   = 'INTERESES'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'INTERESES'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'INTERESES NETOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*(1-(ISNULL(d.InteresesOrdinariosQuita, 0.0)/100.0))*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'INTERESES NETOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*(1-(ISNULL(d.InteresesOrdinariosQuita, 0.0)/100.0))*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'INTERESES QUITA'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*(d.InteresesOrdinariosQuita/100.0)*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'INTERESES QUITA'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesOrdinarios*(d.InteresesOrdinariosQuita/100.0)*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'MORATORIOS'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'MORATORIOS'		INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'MORATORIOS NETOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*(1-(ISNULL(d.InteresesMoratoriosQuita, 0.0)/100.0))*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'MORATORIOS NETOS'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*(1-(ISNULL(d.InteresesMoratoriosQuita, 0.0)/100.0))*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'MORATORIOS QUITA'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*(d.InteresesMoratoriosQuita/100.0)*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Haber  = 'MORATORIOS QUITA'	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, SUM(d.InteresesMoratorios*(d.InteresesMoratoriosQuita/100.0)*e.TipoCambio) FROM Cxp e, CxpD d WHERE e.ID = @ID AND d.ID = e.ID ELSE
IF @Debe   = 'COMISIONES' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Comisiones*TipoCambio    	FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'COMISIONES' 	        INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, Comisiones*TipoCambio    	FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'COMISIONES IVA' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ComisionesIVA*TipoCambio   FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'COMISIONES IVA' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ComisionesIVA*TipoCambio   FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'TOTAL COMISIONES' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ISNULL(Comisiones, 0.0)+ISNULL(ComisionesIVA, 0.0)*TipoCambio FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'TOTAL COMISIONES' 	INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, ISNULL(Comisiones, 0.0)+ISNULL(ComisionesIVA, 0.0)*TipoCambio FROM Cxp WHERE ID = @ID ELSE
IF @Debe   = 'INTERESES ANTICIPADO' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, InteresesAnticipados*TipoCambio FROM Cxp WHERE ID = @ID ELSE
IF @Haber  = 'INTERESES ANTICIPADO' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, InteresesAnticipados*TipoCambio FROM Cxp WHERE ID = @ID ELSE
IF @Debe  IN ('IVA DIF. CAMBIARIA', 'IVA UTI. CAMBIARIA', 'IVA PER. CAMBIARIA', 'IEPS DIF. CAMBIARIA', 'IEPS UTI. CAMBIARIA', 'IEPS PER. CAMBIARIA', 'DIFERENCIA CAMBIARIA', 'UTILIDAD CAMBIARIA', 'PERDIDA CAMBIARIA') OR
@Haber IN ('IVA DIF. CAMBIARIA', 'IVA UTI. CAMBIARIA', 'IVA PER. CAMBIARIA', 'IEPS DIF. CAMBIARIA', 'IEPS UTI. CAMBIARIA', 'IEPS PER. CAMBIARIA', 'DIFERENCIA CAMBIARIA', 'UTILIDAD CAMBIARIA', 'PERDIDA CAMBIARIA')
BEGIN
SELECT @CxImporteTotalMN = (ISNULL(Importe, 0)+ISNULL(Impuestos, 0)-ISNULL(Retencion, 0)-ISNULL(Retencion2, 0)-ISNULL(Retencion3, 0))*TipoCambio, @CxTipoCambio = TipoCambio, @ContactoTipoCambio = ProveedorTipoCambio FROM Cxp WHERE ID = @ID
IF @CxTipoCambio <> 1.0 OR @ContactoTipoCambio <> 1.0
BEGIN
SELECT @CxPicosMN = SUM(Importe)*@CxTipoCambio FROM CxpD WHERE ID = @ID AND UPPER(Aplica) IN ('REDONDEO', 'SALDO A FAVOR', 'ANTICIPOS ACUMULADOS')
SELECT @CxImporteTotalMN = @CxImporteTotalMN - ISNULL(@CxPicosMN, 0)
SELECT @CxIVAMN = @CxImporteTotalMN * IVAFiscal, @CxIEPSMN = @CxImporteTotalMN * IEPSFiscal FROM Cxp WHERE ID = @ID
SELECT @CxImporteAplicaMN = SUM(d.Importe/@ContactoTipoCambio*@CxTipoCambio*CASE WHEN @MovTipo = 'CXP.RE' THEN l.TipoCambio ELSE a.TipoCambio END),
@CxIVAAplicaMN = SUM(d.Importe*a.IVAFiscal/@ContactoTipoCambio*@CxTipoCambio*CASE WHEN @MovTipo = 'CXP.RE' THEN l.TipoCambio ELSE a.TipoCambio END),
@CxIEPSAplicaMN = SUM(d.Importe*a.IEPSFiscal/@ContactoTipoCambio*@CxTipoCambio*CASE WHEN @MovTipo = 'CXP.RE' THEN l.TipoCambio ELSE a.TipoCambio END)
FROM CxpD d
JOIN CxpAplica a  ON a.Mov = d.Aplica AND a.MovID = d.AplicaID AND a.Empresa = @Empresa
LEFT OUTER JOIN CxReevaluacionLog l ON l.Modulo = @Modulo AND l.ID = d.ID AND l.Renglon = d.Renglon AND l.RenglonSub = d.RenglonSub
WHERE d.ID = @ID
SELECT @Diferencia = @CxImporteTotalMN - @CxImporteAplicaMN
SELECT @DiferenciaIVA = @CxIVAMN - @CxIVAAplicaMN,
@DiferenciaIEPS = @CxIEPSMN - @CxIEPSAplicaMN
IF ISNULL(@Diferencia, 0) <> 0
BEGIN
IF @Debe   = 'DIFERENCIA CAMBIARIA' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Diferencia) ELSE
IF @Haber  = 'DIFERENCIA CAMBIARIA' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Diferencia) ELSE
IF @Debe   = 'UTILIDAD CAMBIARIA'   AND @Diferencia > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta,  SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)   VALUES (@Orden, @Cta, @ContUso,  @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Diferencia) ELSE
IF @Haber  = 'UTILIDAD CAMBIARIA'   AND @Diferencia > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta,  SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber)  VALUES (@Orden, @Cta, @ContUso,  @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Diferencia) ELSE
IF @Debe   = 'PERDIDA CAMBIARIA'    AND @Diferencia < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta,  SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)   VALUES (@Orden, @Cta, @ContUso,  @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@Diferencia) ELSE
IF @Haber  = 'PERDIDA CAMBIARIA'    AND @Diferencia < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta,  SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber)  VALUES (@Orden, @Cta, @ContUso,  @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@Diferencia) ELSE
IF @Debe   = 'IVA DIF. CAMBIARIA'  INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA)  ELSE
IF @Haber  = 'IVA DIF. CAMBIARIA'  INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA)  ELSE
IF @Debe   = 'IVA UTI. CAMBIARIA'  AND @DiferenciaIVA > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA) ELSE
IF @Haber  = 'IVA UTI. CAMBIARIA'  AND @DiferenciaIVA > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIVA) ELSE
IF @Debe   = 'IVA PER. CAMBIARIA'  AND @DiferenciaIVA < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIVA) ELSE
IF @Haber  = 'IVA PER. CAMBIARIA'  AND @DiferenciaIVA < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIVA) ELSE
IF @Debe   = 'IEPS DIF. CAMBIARIA' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Haber  = 'IEPS DIF. CAMBIARIA' INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS) ELSE
IF @Debe   = 'IEPS UTI. CAMBIARIA' AND @DiferenciaIEPS > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS)  ELSE
IF @Haber  = 'IEPS UTI. CAMBIARIA' AND @DiferenciaIEPS > 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @DiferenciaIEPS)  ELSE
IF @Debe   = 'IEPS PER. CAMBIARIA' AND @DiferenciaIEPS < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIEPS) ELSE
IF @Haber  = 'IEPS PER. CAMBIARIA' AND @DiferenciaIEPS < 0 INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber) VALUES (@Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, -@DiferenciaIEPS)
END
END
END
ELSE
BEGIN
IF @Debe IS NOT NULL
BEGIN
EXEC xpContAutoCampoExtra @Modulo, @ID, NULL, NULL, @Debe, @Monto OUTPUT, @Ok OUTPUT, @OkRef OUTPUT
IF @Monto IS NOT NULL
INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Debe)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Monto*TipoCambio 	FROM Cxc WHERE ID = @ID
END ELSE
IF @Haber IS NOT NULL
BEGIN
EXEC xpContAutoCampoExtra @Modulo, @ID, NULL, NULL, @Haber, @Monto OUTPUT, @Ok OUTPUT, @OkRef OUTPUT
IF @Monto IS NOT NULL
INSERT #Poliza (Orden, Cuenta, SubCuenta, SubCuenta2, SubCuenta3, Concepto, ContactoEspecifico, Haber)  SELECT @Orden, @Cta, @ContUso, @ContUso2, @ContUso3, @Concepto, @ContactoEspecifico, @Monto*TipoCambio 	FROM Cxc WHERE ID = @ID
END
END
END
RETURN
END