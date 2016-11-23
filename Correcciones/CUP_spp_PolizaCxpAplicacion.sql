USE Cuprum
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
/*Ejemplo Llamado
DECLARE
  @OK INT,
  @OKRef VARCHAR(255) 

  EXEC CUP_spp_PolizaCxpAplicacion
    @PolizaID = 744918, 
    @Modulo = 'CXP',
    @ModuloID =  80407,
    @Ok = @OK OUTPUT,
    @OkRef = @OkRef OUTPUT

  SELECT Ok = @OK, OkRef = @OkRef

*/

      
/********************** CREACION DEL PROCEDIMIENTO *********************************************************/      
	ALTER PROCEDURE dbo.CUP_spp_PolizaCxpAplicacion
(        
  @PolizaID       int,
  @Modulo	      	char(5),
  @ModuloID			INT,
  @Ok			        INT OUTPUT,
  @OkRef			    VARCHAR(255) OUTPUT
)             
AS BEGIN TRY 
  DECLARE 
    @Empresa CHAR(5),
    @Estatus VARCHAR(15),
    @Sucursal INT,
    @Proveedor CHAR(10),
    @Mov CHAR(20),
    @MovTipo CHAR(20),
    @Importe MONEY,
    @Impuestos MONEY,
    @Moneda CHAR(20),
    @TipoCambio FLOAT,
    @AntID INT,
    @AntMov CHAR(20),
    @AntMovID VARCHAR(20),
    @AntMovTipo CHAR(20),
    @AntMovFactor SMALLINT,
    @AntMoneda CHAR(20),
    @AntTC FLOAT,
    @AntTCOriginal FLOAT,
    @ProvCuenta CHAR(20),
    @HOY DATE = GETDATE(),
    @Fecha DATE,
    @PerdidaCambiaria MONEY,
    @UtilidadCambiaria MONEY,
    @MaxRenglon FLOAT,
    @DiferenciaEnDocumentos BIT,
    @DiferenciaEnIVA BIT,
    @CtaIVAXAcreditar CHAR(20),
    @CtaIVAAcreditable CHAR(20)
 
  PRINT('CUP_spp_PolizaCxpAplicacion')
      

  IF @Modulo = 'CXP'
  BEGIN
    SELECT  
      @Empresa = p.Empresa,
      @Sucursal = p.Sucursal,
      @Estatus = p.Estatus,
      @Proveedor = p.Proveedor,
      @Mov = p.Mov,
      @Movtipo  = t.Clave,
      @Importe = p.Importe,
      @Impuestos = p.Impuestos,
      @Moneda = p.Moneda,
      @TipoCambio = p.TipoCambio,
      @AntMov = p.MovAplica,
      @AntMovID = p.MovAplicaID,
      @AntMovTipo   = at.Clave,
      @AntMovFactor  = at.Factor,
      @ProvCuenta = prov.Cuenta,
      @Fecha = p.FechaEmision
    FROM
      Cxp p  
    JOIN MovTipo t ON @Modulo = t.Modulo
                   AND p.Mov = t.Mov
    LEFT JOIN prov  ON p.Proveedor = prov.Proveedor
    LEFT JOIN movtipo aT ON @Modulo = at.Modulo
                          AND p.MovAplica = at.Mov
    WHERE 
      p.Id = @ModuloID

		
  
    IF @MovTipo = 'CXP.ANC'
    AND @Estatus IN ('CONCLUIDO','CANCELADO')
	--AND @AntMovTipo = 'CXP.A'
	--jtorres Cambio para poliza de Aplicacion Devolucion o Bonificacion
    AND (@AntMovTipo = 'CXP.A' OR (@AntMov in('Devol Servicio','Credito Proveedor','Devolucion Gasto') AND @AntMovTipo ='CXP.NC') OR (@AntMov in('Cargo Proveedor') AND @AntMovTipo ='CXP.CA') ) 
				--OR RTrim(LTrim(@AntMovTipo))= 'CXP.NC')
    AND @Moneda <> 'Pesos'
    BEGIN
      
	  

      SELECT     
        @CtaIVAXAcreditar  = '119-210-000-0000',
        @CtaIVAAcreditable = '119-410-000-0000'

		--Aqui se Obtiene El Tipo de Cambio del Movimiento Referencia
      SELECT TOP  1
        @AntID = ant.ID,
        @AntMoneda = ant.Moneda,
        @AntTC = ant.TipoCambio,
        @AntTCOriginal = a.TipoCambio
      FROM
        Cxp ant 
      JOIN Auxiliar a ON 'CXP' = a.Modulo
                      AND ant.ID = a.ModuloID 
                      AND 'CXP' = a.Rama
                      
      WHERE 
        ant.Mov = @AntMov
      AND ant.MovID = @AntMovID
      AND ant.Proveedor = @Proveedor
      ORDER BY
        ant.ID DESC 

		--Cambios jtorres Tipo de Cambio 	
		--Tipo de Cambio para el Movimiento Aplica para verificar si se ha reevaluado cuando se realizó la Aplicación
		
		--Reevaluacion para los movimientos de Credito Proveedor
		IF @AntMov='Credito Proveedor' 
			begin				
				select Top 1 @AntTC=ProveedorTipoCambio 
				from cxp join cxpd on(cxp.id=cxpd.id) 
				where cxp.mov='Reevaluacion Credito' and cxp.proveedor= @Proveedor and AplicaId=@AntMovID
					  and FechaEmision<=@Fecha
				order by FechaEmision desc
			end
        
      --
      DECLARE @Documentos TABLE
      (
        ID INT NOT NULL,
        Mov CHAR(20) NOT NULL,
        MovID VARCHAR(20) NULL,
        MovTipo CHAR(20) NULL,
        Factor SMALLINT NOT NULL,
        OrigenTipo VARCHAR(10) NULL,
        Importe MONEY NOT NULL,
        Moneda CHAR(10) NOT NULL,
        TipoCambio FLOAT NOT NULl,
        Diferencia MONEY NULL
      ) 

      DECLARE @DocVsAntIVA TABLE
      (
        Modulo CHAR(5) NOT NULL,
        ModuloID INT NOT NULL,
        Doc CHAR(20) NOT NULL,
        DocMoviD VARCHAR(20) NOT NULL,
        DocIVA  MONEY NOT NULL,
        DocTC FLOAT NOT NULL,
        AntTC FLOAT NOT NULL,
        Diferencia MONEY NOT NULL
      )
        
      --1) Obtenemos la diferencia de los Documentos vs la Aplicacion y despues del Anticipo vs la Aplicacion.
      INSERT INTO @Documentos ( ID,Mov,Movid,MovTipo,Factor,OrigenTipo,Importe,Moneda,TipoCambio,Diferencia)
      -- Documentos X Pagar
      SELECT 
          doc.ID,
          doc.Mov,
          doc.Movid,
          docT.Clave,
          doct.Factor,
          doc.OrigenTipo,
          d.Importe,
          doc.Moneda,
          doc.TipoCambio,
          --Diferencia  = (d.Importe  *  (doc.TipoCambio - @TipoCambio)) * ISNULL(doct.Factor,1)
		  Diferencia  = (d.Importe  *  (tcRev.TipoCambio - @TipoCambio)) * ISNULL(doct.Factor,1)		  
      FROM cxp p
        JOIN cxpD d ON (p.id=d.id)
      JOIN cxp doc ON d.Aplica = doc.Mov 
                  and d.AplicaID = doc.Movid 
      JOIN Movtipo docT ON 'CXP' = docT.Modulo
                        AND d.Aplica = doct.Mov
			--********** Jtorres Cambios se agregan las opciones de TC para caso en que se regeneren las pólizas tome el TC Reevaluado 
			--que le corresponde en base a la fecha 
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
		--********
      WHERE 
        p.Id = @ModuloID
      AND ISNULL(d.Aplica,'') NOT IN ('Redondeo','')
      AND doc.Moneda = @Moneda 
      UNION 
      -- Anticipo
      SELECT 
        Id = @AntID,
        Mov = @AntMov,
        Movid = @AntMovID,
        MovTipo = @AntMovTipo,
        Factor = @AntMovFactor,
        OrigenTipo = NULL,
        Importe = @Importe,
        Moneda =  @AntMoneda,
        TipoCambio = @AntTC,
        Diferencia =  ROUND((@Importe  *  (@AntTC - @TipoCambio)) * ISNULL(@AntMovFactor,1),2)
      WHere 
        @AntMoneda = @Moneda	
	
	--jtorres
		--select @TipoCambio
		--select * from @Documentos
	--jtorres
	   
      IF @@rowcount > 0
        SET @DiferenciaEnDocumentos = 1

      --2) Verificamos si existe una diferencia entre los IVA provisionados por los Documentos y el del Anticipo.
      --INSERT INTO @DocVsAntIVA ( Modulo, ModuloID, Doc, DocMoviD, DocIVA, DocTC, AntTC, Diferencia)
      --SELECT DISTINCT
      --  Modulo = 'COMS',
      --  ModuloID  = c.ID,
      --  Doc = c.Mov,
      --  DocMovID = c.MovID,
      --  DocIVA = c.Impuestos,
      --  DocTC = c.TipoCambio,
      --  AntTC = @AntTC,
      --  Diferencia  =   ROUND(c.Impuestos  *  (@AntTCOriginal - c.TipoCambio),2)
      --FROM  
      --   @Documentos dctos 
      --CROSS APPLY( SELECT TOP 1
      --              OID 
      --             FROM
      --              dbo.fnCMLMovFlujo('CXP',dctos.ID,0) mf
      --             WHERE 
      --              mf.Indice < 0 
      --             AND mf.OModulo = 'COMS') origen
      -- JOIN Compra c ON origen.OID = c.ID
      --WHERE 
      --  ISNULL(dctos.OrigenTipo,'')  = 'COMS'
      --AND ISNULL(c.IvaFiscal,0) <> 0
      --AND ISNULL(c.Impuestos,0) > 0
      --UNION 
      --SELECT DISTINCT
      --  Modulo = 'GAS',
      --  ModuloID  = g.ID,
      --  Doc = g.Mov,
      --  DocMovID = g.MovID,
      --  DocIVA = g.Impuestos,
      --  DocTC = g.TipoCambio,
      --  AntTC = @AntTC,
      --  Diferencia  =   ROUND(g.Impuestos  *  (@AntTCOriginal - g.TipoCambio),2)
      --FROM  
      --   @Documentos dctos 
      --CROSS APPLY( SELECT TOP 1
      --              OID 
      --             FROM
      --              dbo.fnCMLMovFlujo('GAS',dctos.ID,0) mf
      --             WHERE 
      --              mf.Indice < 0 
      --             AND mf.OModulo = 'GAS') origen
      -- JOIN Gasto g ON origen.OID = g.ID
      --WHERE 
      --  ISNULL(dctos.OrigenTipo,'')  = 'GAS'
      --AND ISNULL(g.IvaFiscal,0) <> 0
      --AND ISNULL(g.Impuestos,0) > 0

	  --jtorres se cambio el Insert del Diferencias del IVA
	  INSERT INTO @DocVsAntIVA ( Modulo, ModuloID, Doc, DocMoviD, DocIVA, DocTC, AntTC, Diferencia)
	  SELECT DISTINCT
        Modulo = p.OrigenTipo,
        ModuloID  = p.ID,
        Doc = p.Mov,
        DocMovID = p.MovID,
        DocIVA = p.Impuestos,
        DocTC = p.TipoCambio,
        AntTC = @AntTC        
		,Diferencia  = ((impuesto_aplica.ImpuestoAplica *  (tcRev.TipoCambio - @TipoCambio)) * ISNULL(doct.Factor,1) ) * (-1) --Se multiplica por -1 por que el IVA tendra el sentido contrario al importe , si el importe es Perdida en el Iva sera Utilidad y veiceversa
		FROM cxp p
        JOIN cxpD d ON (p.id=d.id)
      JOIN cxp doc ON d.Aplica = doc.Mov 
                  and d.AplicaID = doc.Movid 
      JOIN Movtipo docT ON 'CXP' = docT.Modulo
                        AND d.Aplica = doct.Mov
			--********** Jtorres Cambios se agregan las opciones de TC para caso en que se regeneren las pólizas tome el TC Reevaluado 
			--que le corresponde en base a la fecha 
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
					CROSS APPLY( SELECT   
									ImpuestoAplica = ROUND((IsNull(CA.ImporteTotal,0)*IsNull(CA.IvaFiscal,0)) * (p.TipoCambio / IsNull(p.ProveedorTipoCambio,1)),4,1)
								FROM cxpaplica CA
								WHERE CA.id=p.id
							)impuesto_aplica
		--********
      WHERE 
        p.Id = @ModuloID
      AND ISNULL(d.Aplica,'') NOT IN ('Redondeo','')
      AND doc.Moneda = @Moneda 
	  
	  ---*******JTORRES

	      
      IF @@rowcount > 0
        SET @DiferenciaEnIVA = 1	  
      

      --3 ) Si existe una diferencia cambiaria en la cuenta de Proveedores o el Iva del Anticipo VS el iva del Documento,
      --    entonces  generamos la póliza.
      IF ISNULL(@DiferenciaEnDocumentos,0) = 1 
      OR ISNULL(@DiferenciaEnIVA,0) = 1
      BEGIN
        DELETE ContD WHERE ID = @PolizaID 
      
        IF ISNULL(@DiferenciaEnDocumentos,0) = 1 
        BEGIN

          DECLARE @Diferencias TABLE
          (
            Tipo VARCHAR(20) NOT NULL,
            Importe MONEY  NULL
          )

          INSERT INTO @Diferencias (Tipo, Importe)
          SELECT  Tipo = 'Utilidad', Diferencia =  SUM(ISNULL(Diferencia,0)) FROM @Documentos WHERE ROUND(ISNULL(Diferencia,0),2) > 0  
          UNION
          SELECT  Tipo = 'Perdida', Diferencia = ABS(SUM(ISNULL(Diferencia,0))) FROM @Documentos WHERE ROUND(ISNULL(Diferencia,0),2)  < 0 
          
           DELETE @Diferencias WHERE ISNULL(Importe,0)  = 0 

          --Insertamos Primero las diferencias agrupadas a la cuenta de proveedores.
           INSERT INTO ContD 
          (
            Id,
            Renglon,
            RenglonSub,
            Cuenta,
            SubCuenta, -- ( Centro Costos )
            Concepto,
            Debe,
            Haber,
            Empresa,
            Ejercicio,
            Periodo,
            FechaContable,
            Sucursal,
            SucursalContable,
            SucursalOrigen
          )
          SELECT 
            @PolizaID,
            Renglon =  CAST(2048 * ROW_NUMBER() OVER (ORDER BY df.Tipo,df.Importe) AS FLOAT),   
            RenglonSub = 0, 
            Cuenta = @ProvCuenta,
            Subcuenta = NULL, 
            Concepto = CASE  ISNULL(df.Tipo,'')  
                         WHEN'Utilidad' THEN 
                           'Ganan. C. Prov'
                         ELSE 
                           'Perd. C. Prov'
                       END,
            Debe = CASE ISNULL(df.Tipo,'')
                     WHEN  'Utilidad' THEN 
                        df.Importe
                     ELSE 
                       NULL
                    END,
            Haber = CASE ISNULL(df.Tipo,'')
                     WHEN 'Perdida' THEN 
                        df.Importe
                     ELSE 
                       NULL
                    END,
            Empresa = @Empresa,
            Ejercicio = YEAR(@Fecha),
            Periodo = MONTH(@Fecha),
            FechaContable = @Fecha,
            Sucursal = @Sucursal,
            SucursalContable = @Sucursal,
            SucursalOrigen = @Sucursal
          FROM 
            @Diferencias df 
          WHERE 
            ROUND(ISNULL(df.Importe,0),2) <> 0

          SELECT @MaxRenglon = MAX(Renglon) FROM ContD WHERE ID = @PolizaID 
          
          --Insertamos desglose de las diferencias por Documento.
          INSERT INTO ContD 
          (
            Id,
            Renglon,
            RenglonSub,
            Cuenta,
            SubCuenta, -- ( Centro Costos )
            Concepto,
            Debe,
            Haber,
            Empresa,
            Ejercicio,
            Periodo,
            FechaContable,
            Sucursal,
            SucursalContable,
            SucursalOrigen
          )
          SELECT 
            @PolizaID,
            Renglon =  @MaxRenglon + CAST(2048 * ROW_NUMBER() OVER (ORDER BY dtos.Diferencia DESC) AS FLOAT),   
            RenglonSub = 0, 
            Cuenta = CASE 
                       WHEN ISNULL(Diferencia,0) > 0  THEN
                         '740-100-000-0000'  --Ganancia
                       ELSE 
                         '740-200-000-0000' -- Perdida 
                     END,
            Subcuenta = NULL, 
            Concepto = LTRIM(RTRIM(dtos.Mov)) + ' ' + dtos.MovID,
            Debe = CASE --PERDIDA
                       WHEN ISNULL(Diferencia,0) < 0  THEN
                         ABS(ROUND(ISNULL(dtos.Diferencia,0),2))
                       ELSE 
                         NULL
                     END,
            Haber = CASE --Ganancia
                       WHEN ISNULL(Diferencia,0)  > 0  THEN
                         ROUND(ISNULL(dtos.Diferencia,0),2)
                       ELSE 
                         NULL
                     END,
            Empresa = @Empresa,
            Ejercicio = YEAR(@Fecha),
            Periodo = MONTH(@Fecha),
            FechaContable = @Fecha,
            Sucursal = @Sucursal,
            SucursalContable = @Sucursal,
            SucursalOrigen = @Sucursal
          FROM 
            @Documentos dtos
          WHERE 
            ROUND(ISNULL(dtos.Diferencia,0),2) <> 0
          ORDER BY  
            dtos.Diferencia DESC
        END
        
    
	

        IF ISNULL(@DiferenciaEnIVA,0) = 1
        BEGIN
          DECLARE @DiferenciasIVA TABLE
          (
            Tipo VARCHAR(20) NOT NULL,
            Importe MONEY  NULL
          )

          INSERT INTO @DiferenciasIVA (Tipo, Importe)
          SELECT  Tipo = 'Utilidad', Diferencia =  SUM(ISNULL(Diferencia,0)) FROM @DocVsAntIVA WHERE ROUND(ISNULL(Diferencia,0),2) > 0  
          UNION
          SELECT  Tipo = 'Perdida', Diferencia = ABS(SUM(ISNULL(Diferencia,0))) FROM @DocVsAntIVA WHERE ROUND(ISNULL(Diferencia,0),2)  < 0 	  
	


          DELETE @DiferenciasIVA WHERE ISNULL(Importe,0)  = 0 
            
          SELECT @MaxRenglon = MAX(Renglon) FROM ContD WHERE ID = @PolizaID 


		 	  
  
          --Insertamos Primero las diferencias IVA agrupadas a la cuenta de IVA .
           INSERT INTO ContD 
          (
            Id,
            Renglon,
            RenglonSub,
            Cuenta,
            SubCuenta, -- ( Centro Costos )
            Concepto,
            Debe,
            Haber,
            Empresa,
            Ejercicio,
            Periodo,
            FechaContable,
            Sucursal,
            SucursalContable,
            SucursalOrigen
          )
          SELECT 
            @PolizaID,
            Renglon =   ISNULL(@MaxRenglon,0) + CAST(2048 * ROW_NUMBER() OVER (ORDER BY df.Tipo,df.Importe) AS FLOAT),   
            RenglonSub = 0, 
            Cuenta = @CtaIVAXAcreditar,
            Subcuenta = NULL, 
            Concepto = CASE ISNULL(df.Tipo,'')
                         WHEN 'Utilidad' THEN 
                           'Ganan. C. IVA'
                         ELSE 
                           'Perd. C. IVA' + df.Tipo
                       END,
            Debe = CASE ISNULL(df.Tipo,'')
                     WHEN  'Utilidad' THEN 
                        df.Importe
                     ELSE 
                       NULL
                    END,
            Haber = CASE ISNULL(df.Tipo,'')
                     WHEN 'Perdida' THEN 
                        df.Importe
                     ELSE 
                       NULL
                    END,

			--***Jtorres
			--Debe = CASE ISNULL(df.Tipo,'')
   --                  WHEN 'Perdida' THEN 
   --                     df.Importe
   --                  ELSE 
   --                    NULL
   --                 END,
			-- Haber = CASE ISNULL(df.Tipo,'')
   --                  WHEN  'Utilidad' THEN 
   --                     df.Importe
   --                  ELSE 
   --                    NULL
   --                 END,  
			----******          
            Empresa = @Empresa,
            Ejercicio = YEAR(@Fecha),
            Periodo = MONTH(@Fecha),
            FechaContable = @Fecha,
            Sucursal = @Sucursal,
            SucursalContable = @Sucursal,
            SucursalOrigen = @Sucursal
          FROM 
            @DiferenciasIVA df 
          WHERE 
            ROUND(ISNULL(df.Importe,0),2) <> 0			
		  --*****

          SELECT @MaxRenglon = MAX(Renglon) FROM ContD WHERE ID = @PolizaID 

          --Insertamos las Diferencias IVA agrupadas por documento.
          INSERT INTO ContD 
          (
            Id,
            Renglon,
            RenglonSub,
            Cuenta,
            SubCuenta, -- ( Centro Costos )
            Concepto,
            Debe,
            Haber,
            Empresa,
            Ejercicio,
            Periodo,
            FechaContable,
            Sucursal,
            SucursalContable,
            SucursalOrigen
          )
          SELECT 
            @PolizaID,
            Renglon =  ISNULL(@MaxRenglon,0) + CAST(2048 * ROW_NUMBER() OVER (ORDER BY avd.Diferencia DESC) AS FLOAT),   
            RenglonSub = 0, 
            Cuenta = CASE 
                       WHEN ISNULL(avd.Diferencia,0) > 0  THEN
                         '740-100-000-0000'  --Ganancia
                       ELSE 
                         '740-200-000-0000' -- Perdida 
                     END,
            Subcuenta = NULL, 
            Concepto = LEFT(LTRIM(RTRIM(avd.Doc)) + ' ' + avd.DocMoviD,50),
            Debe = CASE --PERDIDA
                       WHEN ISNULL(avd.Diferencia,0) < 0  THEN
                         ABS(ROUND(ISNULL(avd.Diferencia,0),2))
                       ELSE 
                         NULL
                     END,
            Haber = CASE --Ganancia
                       WHEN ISNULL(avd.Diferencia,0)  > 0  THEN
                         ROUND(ISNULL(avd.Diferencia,0),2)
                       ELSE 
               NULL
                     END,

			--****Cambio Jtorres
			--Debe = CASE --Ganancia
   --                    WHEN ISNULL(avd.Diferencia,0)  > 0  THEN
   --                      ROUND(ISNULL(avd.Diferencia,0),2)
   --                    ELSE 
   --            NULL
   --                  END,
			--Haber = CASE --PERDIDA
   --                    WHEN ISNULL(avd.Diferencia,0) < 0  THEN
   --                      ABS(ROUND(ISNULL(avd.Diferencia,0),2))
   --                    ELSE 
   --                      NULL
   --                  END,            
	-----********************
            Empresa = @Empresa,
            Ejercicio = YEAR(@Fecha),
            Periodo = MONTH(@Fecha),
            FechaContable = @Fecha,
            Sucursal = @Sucursal,
            SucursalContable = @Sucursal,
            SucursalOrigen = @Sucursal
          FROM 
            @DocVsAntIVA avd
          WHERE 
            ROUND(ISNULL(avd.Diferencia,0),2) <> 0
          ORDER BY  
            avd.Diferencia DESC	

        END
 
        IF @Estatus = 'CANCELADO'
        BEGIN
          UPDATE ContD SET Debe = Debe * -1 , Haber = Haber * -1  WHERE ID = @PolizaID
        END

      END
        
    END
  END 

  RETURN      
END  TRY 
BEGIN CATCH
  SELECT @OkREf  = ERROR_MESSAGE()
END CATCH


GO

