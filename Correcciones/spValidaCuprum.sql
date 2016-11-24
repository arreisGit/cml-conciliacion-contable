/****** Object:  StoredProcedure [dbo].[spValidaCuprum]    Script Date: 24/11/2016 12:16:31 p.m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [dbo].[spValidaCuprum] @Modulo      char(5),              
                                    @ID          int,                
                                    @Accion      char(20),                
                                    @Base        char(20),                
                                    @GenerarMov  char(20),                
                                    @Usuario     char(10),                
                                    @Ok          int          OUTPUT,                
                                    @OkRef       varchar(255)  OUTPUT              
AS BEGIN    
          
  --Kike Sierra: 30/OCT/2015: Se cambio la configracion de las siguientes opciones para evitar conflicto con los linked server.
  SET ANSI_NULLS, ANSI_WARNINGS ON;

  DECLARE
    @Mov Char(20),                  
    @Directo Bit ,                   
    @OrigenId Varchar(20),                  
    --Kike Sierra: Inicio Variables para la validacion de transferencias de inventarios.                  
    @Almacen CHAR(10),                  
    @AlmacenDestino CHAR(10),                  
    --Kike Sierra: FIN Variables para la validacion de transferencias de inventarios.                  
    -- variables actualizacion situacion en pedido. Judith Ramirez 15-ene-2013*/                
    @Cte varchar(10),                 
    @Estatus CHAR(15),                
    @EstatusCte varchar(15),                 
    @TipoCondicion varchar(20),                
    -- fin variables actualizacion situtuacion pedido                
    /* Omar chavez 01/04/2013*/                
    @ErrorNum      Int,                
    @ErrorMensaje  Varchar(100),                

    @ErrorAccion   Varchar(100),                
    @Situacion     Varchar(100),                
    @MovClave      Varchar(100),                
    --Kike Sierra:Declaracion Variables para Validar que la CantidadA no sea mayor a la CantidadPendiente en Un Pedido*/                
    @Articulo     CHAR(20),                
    @Subcuenta    VARCHAR(20),                
    @CantidaDA    FLOAT,                
    @CantidadPendiente FLOAT,                
    @CantidadReservada FLOAT,
    --Kike Sierra: 09/OCT/2015: Para la Venta Mostrador.
    @CUP_VtaMostrador BIT = 0,
    --Kike SIerra: 20/OCT/2015: Para validar los cortes.
    @Empresa     CHAR(5),
    @SubClave    VARCHAR(20),
    @CtaDinero   CHAR(10),
    @Refacturado BIT,
    @CteInterCompañia BIT
	--
        
  /***************************** Omar chávez    08/enero/2015   Se agregaron las claves de afectacion *******************************************************/     
  IF @Modulo = 'INV'                              
  BEGIN        
  
    --Inicializamos las Variables                  
    SELECT 
        @Mov = i.Mov,
        @MovClave = t.Clave             
    FROM                  
        inv i
    JOIN movtipo t ON @Modulo = t.Modulo
                    AND i.Mov = t.Mov             
    WHERE                  
        i.ID = @ID         

  
    --Kike Sierra 12/05/2015: Procedimiento Almacenado encargado de validar el flujo de la "Oferta Servicio" de las solicitudes
     EXEC spCMLServicioSolicitud @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,'VALIDAR',@Ok OUTPUT,@OkRef OUTPUT  
   
     --Kike Sierra: 05/10/2015: Validaciones simples del modulo de inventarios que no requieren un procedimiento dedicado.  
     EXEC CUP_spp_ValidacionesSimplesINV @Modulo,@ID,@Mov,@MovClave,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT        
   
	  --Carlos Orozco: 09/02/2015 Validacion Para Impedir Movimientos De Un Almacén IMMEX a un Almacen No IMMEX
    EXEC CUP_SPP_ValidacionesInvIMMEX @Modulo, @ID, @Mov, @MovClave, @Accion, @Usuario, @Ok OUTPUT, @OkRef OUTPUT                 
  END                  
  ------


  IF @Modulo='COMS'
  Begin
     Select @MovClave=Movtipo.Clave
     From Movtipo, Compra
     Where  Movtipo.Modulo=@Modulo
     And    Movtipo.Mov=Compra.Mov
     And    Compra.ID=@ID
  End
        


  IF @Modulo='VTAS'
  Begin
     SELECT 
       @Estatus = Venta.Estatus,
       @Mov = Venta.Mov,
       @MovClave=Movtipo.Clave,
       @Situacion = venta.Situacion,
        --Kike Sierra: 09/OCT/2015
       @CUP_VtaMostrador  = Venta.CUP_VtaMostrador,
       @Refacturado = Venta.Refacturado,
       @CteInterCompañia = Cte.Intercompania
       -- 
     From   
      Venta
    LEFT OUTER JOIN Cte on Venta.Cliente = Cte.Cliente
     JOIN  Movtipo ON @Modulo = Movtipo.Modulo
                   AND Venta.Mov = Movtipo.Mov
     WHERE  
        Venta.ID=@ID
  End


  IF @Modulo='PROD'
  Begin
     Select @MovClave=Movtipo.Clave
     From   Movtipo, Prod
     Where  Movtipo.Modulo=@Modulo
     And    Movtipo.Mov=Prod.Mov
     And    Prod.ID=@ID
  End

  IF @Modulo='GAS'
  BEGIN
     SELECT @MovClave=Movtipo.Clave
     FROM   Movtipo, Gasto
     WHERE  Movtipo.Modulo=@Modulo
     And    Movtipo.Mov=Gasto.Mov
     And    Gasto.ID=@ID
  END

  IF @Modulo='CXC'
  Begin
     Select 
      @Estatus = Cxc.Estatus,
      @Mov = Cxc.Mov,
      @MovClave=Movtipo.Clave
     From   Movtipo, CXC
     Where  Movtipo.Modulo=@Modulo
     And    Movtipo.Mov=CXC.Mov
     And    CXC.ID=@ID
  End

  IF @Modulo='CXP'
  Begin
     Select 
        @MovClave = t.Clave,
        @Estatus = p.Estatus
     From   
       CXP p 
     JOIN movtipo t ON @Modulo = t.Modulo
                    AND p.Mov = t.mov
     Where 
        p.ID=@ID
  End
             
  IF @Modulo='DIN'
  BEGIN
     SELECT 
       @Empresa  = d.Empresa,
       @Estatus = d.Estatus,
       @CtaDinero = d.CtaDinero,
       @Mov = d.Mov,
       @MovClave= t.Clave,
       @SubClave = t.SubClave
     FROM   
       Dinero d
     JOIN Movtipo t ON @Modulo = t.Modulo 
                    AND d.Mov = t.Mov
     WHERE  
       d.ID=@ID
  END             
                
                
  /****************************************************************************[VENTAS]*********************************************************************/                             
  /*Kike Sierra: 31/05/2013: Debido a los cambios por Oferta Servicio, la validacion original " /*EBG:06/Mar/2013 Fecha Requerida*/"                 
  de este segmento ya no es necesaria.*/                
  IF @Modulo='VTAS' AND ((SELECT t.clave 
                          FROM venta v 
                          JOIN movtipo t ON v.Mov = t.Mov  
                                        AND t.Modulo = 'VTAS' WHERE v.id = @iD) IN ('VTAS.C', 'VTAS.P', 'VTAS.S', 'VTAS.PR', 'VTAS.EST', 'VTAS.F'))                 
  BEGIN             
    --Kike Sierra: 31/05/2013:                 
    IF (SELECT Estatus FROM Venta WHERE id = @ID) = 'SINAFECTAR'                
      UPDATE Venta SET FechaOriginal = ISNULL(FechaRequerida,FechaEmision)  WHERE id = @ID                
                   
    --Kike Sierra: 13/06/2013: Validar que no se generen Ventas Perdidas por cantidades superior a lo pendiente (Reservado+ Pendiente) -                
    IF  @Accion ='GENERAR'                   
    AND @Base = 'Seleccion'                
    AND @GenerarMov in ('Venta Perdida','Venta No Perdida')                
    BEGIN                 
      --Declaración del cursor                
       
      DECLARE crCant CURSOR FAST_FORWARD LOCAL FOR                        
      SELECT                
        ISNULL(Articulo,''),                
        ISNULL(SubCuenta,''),                
        ISNULL(CantidadA,0.00),                
        ISNULL(CantidadReservada,0.00),                
        ISNULL(CantidadPendiente,0.00)                
      FROM                 
        VentaD                
      WHERE                
        id = @ID                
                    
      -- Apertura del cursor  
OPEN crCant        
                
      -- Lectura de la primera fila del cursor                
      FETCH crCant INTO @Articulo, @SubCuenta, @CantidadA,@CantidadReservada,@CantidadPendiente                
                   
      WHILE (@@FETCH_STATUS = 0 )                
      BEGIN                
    
        IF ((@CantidadPendiente + @CantidadReservada) < @CantidadA)                
          SELECT 
		        @Ok = 99932,                
            @OkRef = ISNULL(@OkRef,'') + 'La Cantidad a Afectar supera la Cantidad Pendiente<BR>Articulo: ' 
                + @Articulo + ' ' + @SubCuenta  
                + '<BR>CantidadA: ' + CAST(@CantidadA AS VARCHAR) 
                + '<BR>CantidadPendiente: ' + CAST(@CantidadPendiente + @CantidadReservada AS VARCHAR) 
                + '<BR>'                
                       
        FETCH crCant INTO @Articulo, @SubCuenta, @CantidadA,@CantidadReservada,@CantidadPendiente                
      END
                   
      -- Cierre del cursor                
      CLOSE crCant                
                
      -- Liberar los recursos                
      DEALLOCATE crCant                
    END                
    ------/              
     
     --Kike SIerra: 13/06/2013: Impedir que se afecten los pedidos de forma directa                
    IF  @Accion = 'AFECTAR'                
    AND (@Mov = 'Pedido' AND @MovClave = 'VTAS.P')               
    AND (SELECT NULLIF(Origen,'')  FROM Venta WHERE Id = @Id) IS NULL            
    AND ISNULL(@Situacion,'') <> 'Por Enviar a Venta Perdida'    
    AND ISNULL(@Refacturado,0) = 0
    AND ISNULL(@CteInterCompañia,0) = 0
    BEGIN                
      SELECT @Ok = '99933',@OkRef = 'No se pueden realizar pedidos Directos.'                
    END                
  END                
                         
  -- Omar Chávez                  
  IF @Modulo In('VTAS') 
  AND @Accion In('CANCELAR')
  AND (Select Isnull(MovID,'') From Venta Where ID=@ID)=''                  
  BEGIN                  
    SELECT  @Ok =10065, @OkRef='No se debe cancelar si no tiene Folio'                  
  END                   
                   
                   
                   
  -- Omar Chávez para addenda Sanmina, verifica que no falte la orden de compra                   
  IF @Modulo = 'VTAS'                   
  AND  @MovClave In ('VTAS.C','VTAS.P','VTAS.F')                  
  AND  @Accion IN ('AFECTAR','VERIFICAR')                   
  AND (Select cliente from venta where id=@ID)='2156 '        
  AND ISNULL(@CUP_VtaMostrador,0) = 0 -- Kike Sierra: 31/OCT/2015: Para la venta Mostrador
  BEGIN                  
                   
    IF ISNULL((Select OrdenCompra 
              FROM Venta 
              WHERE ID=@ID),'') = ''                   
    BEGIN                  
      SELECT @Ok = 99990,@OkRef='Es obligatorio incluir la  orden de compra en los movimiento de SANMINA'            
    END                            
  END                  
  ------                  
                
                
  --- Omar Chávez 04/abril/2013  se hizo un sp para las validaciones de descuentos por que ya era muy grande y se necesitaba llamar independiente para                
  --  Validar el boton de "enviar correo" en el pedido                
  --IF @Modulo = 'VTAS'                   
  --   AND  (Select t.Clave  FROM  venta v JOIN movtipo t ON v.mov = t.mov WHERE t.Modulo = @Modulo AND v.Id = @ID)  = 'VTAS.P'                  
  --   AND  @Accion ='AFECTAR'                   
  --   AND  (SELECT Mov FROM Venta WHERE id = @ID) in ('Pedido', 'Cotizacion')                  
  --   AND  (Select Estatus FROM venta WHERE ID = @ID) = 'SINAFECTAR'                   
  --BEGIN                  
  EXEC dbo.spCuprumValidaDescuentos @Modulo,                
            @ID,                  
            @Accion,      
      @Usuario,  
      @Ok OUTPUT,                  
            @OkRef   OUTPUT                
  --End                  
                              
   --Kike Sierra: 01/04/2014: Valida los flujos en relacion a las Facturas Anticipo creadas y aplicadas de forma automatica con un pedido ligado.          
  EXEC spCuprumValidaFlujoFacturasAntAuto @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT          
                          
/*******************************************************************[FIN VENTAS]***************************************************************************/                
                
                
  /*Validacion genera orden de produccion*/                   
  IF EXISTS(SELECT
              Clave 
            FROM
              dbo.Prod 
            JOIN dbo.MovTipo ON dbo.Prod.Mov = dbo.MovTipo.Mov 
            WHERE 
              Modulo='PROD'
            AND Clave='PROD.O'
            AND ID=@ID)     
  BEGIN           
    EXEC spValidaOrdenProduccionCuprum @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT          
  END      
  
                
   /*Kike Sierra: 21/01/2013: Validaciones Produccion*/                             
  IF @Modulo = 'PROD'                
  AND (Select t.Clave   FROM  Prod p JOIN movtipo t ON p.mov = t.mov  WHERE p.ID= @ID AND t.Modulo = 'PROD') In ('PROD.O')                   
  AND  @Accion ='AFECTAR'                   
  AND (SELECT Estatus FROM prod WHERE id = @ID) IN ('SINAFECTAR','BORRADOR')                
  BEGIN                   
  -- Si se trata de afectar una orden produccion donde tenga la ruta vacia en cualquiera de los articulo del detalle.                
      IF (EXISTS(SELECT * FROM ProdD WHERE ID = @ID AND NULLIF(LTRIM(RTRIM(Ruta)),'') IS NULL))                 
      OR (NOT EXISTS(SELECT * FROM dbo.ProdProgramaRuta WHERE id = @id) AND @Usuario <> 'PRODAUT')                
      OR (@Usuario = 'PRODAUT' AND EXISTS(SELECT * FROM ProdD WHERE id = @ID AND (NULLIF(LTRIM(RTRIM(Centro)),'') IS NULL OR NULLIF(LTRIM(RTRIM(Estacion)),'') IS NULL)))                
          OR (@Usuario <> 'PRODAUT' AND EXISTS(SELECT                
      ppr.Centro,                
      ppr.Estacion                
      FROM                
      ProdD d JOIN dbo.ProdProgramaRuta ppr ON d.Articulo = ppr.Producto AND d.SubCuenta = ppr.SubProducto AND d.ProdSerieLote = ppr.Lote AND d.id = ppr.ID                
      WHERE                
      d.id = @ID                
      AND (NULLIF(LTRIM(RTRIM(ppr.Centro)),'') IS NULL OR NULLIF(LTRIM(RTRIM(ppr.Estacion)),'') IS NULL)))                
          Begin                  
              SELECT                  
                  @OkRef='Para poder Continuar es Necesario que los Productos tenga Ruta, Centro y Estacion.<BR><BR>Id: '+ CAST(@ID AS VARCHAR) ,                  
              @Ok = 99850                  
          End                            
  End                  
                  
                                 
                      
  IF @Modulo In('CXC') AND @Accion In('AFECTAR','VERIFICAR')                  
  BEGIN                  
    SELECT @Mov=ISNULL(Mov,'')                  
    FROM Cxc WHERE ID=@ID                  
                  
	  IF (SELECT  ISNULL(Clave,'') FROM MovTipo WHERE Modulo='CXC' AND LTRIM(RTRIM(ISNULL(Mov,'')))=LTRIM(RTRIM(@Mov))) ='CXC.C'                  
	    IF (SELECT LTRIM(RTRIM(ISNULL(CtaDinero,''))) FROM CXC WHERE ID=@ID) =''                  
				     SELECT @Ok=40120--,@OkRef=' Falta indicar la cuenta de dinero para generar poliza contable'                  
        
    --Kike Sierra: 07/05/2014: Valida de manera general los movs de cxc             
    EXEC spCuprumValidaCxC @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT             
             
    --Kike Sierra: 30/07/2014: Valida que los Cheques DEvueltos esten asignados a un cheque.   
    EXEC spCuprumVencimientoChequeDevuelto @Modulo,@ID,@Accion,'VALIDAR',@Ok OUTPUT,@OkRef OUTPUT                        
                  
  END                  

  /* Apartado CXP */
  IF @Modulo In('CXP') AND @Accion In('AFECTAR','VERIFICAR')
  BEGIN                  
	  SELECT @Mov=ISNULL(Mov,'')                  
	  FROM Cxp WHERE ID=@ID                  
                  
	  IF (SELECT  ISNULL(Clave,'') FROM MovTipo WHERE Modulo='CXP' AND LTRIM(RTRIM(ISNULL(Mov,'')))=LTRIM(RTRIM(@Mov))) ='CXP.P'                  
		  IF (SELECT LTRIM(RTRIM(ISNULL(CtaDinero,''))) FROM CXP WHERE ID=@ID) =''                  
					  SELECT @Ok=40120--,@OkRef=' Falta indicar la cuenta de dinero para generar poliza contable'                  
       
    -- Alejandra Camarena Barrón (INTELISIS): 2016/11/24: Valida los flujos permitidos en Cxp
    EXEC CUP_SPP_ValidaFlujosCxp @ID,
                                @Accion,
                                @Usuario,
                                @OK OUTPUT,
                                @OkREF OUTPUT           
  END
 
 /**** Apartado COMS******/                
 IF @Modulo IN ('COMS')AND (SELECT LTRIM(RTRIM(ISNULL(GrupoTrabajo,''))) FROM Usuario WHERE Usuario = @Usuario)  NOT IN('ADMINISTRADOR','COMPRAS','CONTA')                  
 BEGIN                  
     -- si es compras y si no es de los usuarios con privilegio, validar                   
     -- que no permita entradas de compra directas.                   
                    
   SELECT @Mov=ISNULL(Mov,''), @Directo=ISNULL(Directo,1),@OrigenId=ISNULL(OrigenID,'')                  
   FROM Compra WHERE ID=@ID                  
                       
                   
   IF  EXISTS (SELECT TOP 1 ISNULL(AplicaID,'')  FROM CompraD WHERE ID=@ID AND ISNULL(AplicaID,'')='' )                  
    SET @OrigenID=''                    
   ELSE                   
    SET @OrigenID='OK'                    
     IF (SELECT  ISNULL(Clave,'') FROM MovTipo WHERE Modulo='COMS' AND LTRIM(RTRIM(ISNULL(Mov,'')))=LTRIM(RTRIM(@Mov))) ='COMS.F'                  
   BEGIN                     
     IF @Directo = 1 OR @OrigenId = ''                  
   SELECT @Ok =20380,@OkRef='Se requiere que el origen sea una Orden de compra'                  
                                                 
   END           
 END                   
                  
                  
  IF @Modulo ='COMS'
  AND @ACCION IN ('VERIFICAR','AFECTAR','GENERAR')
  BEGIN                 
    


	  /*Kike Sierra: 13/06/2013: Que no permita afectar Entradas compra con articulos categoria "Acero Inox" ,                
		y que en el serie lote mov no se les haya especificado certificado.*/                                
		--Paso 1 : Si el mov es una Entrada Compra                
		IF ((SELECT t.clave FROM compra c JOIN movtipo t ON c.Mov = t.Mov  AND t.Modulo = 'COMS' WHERE c.id = @iD ) IN ('COMS.F','COMS.EG'))                
		BEGIN                
			--Paso 2 : Si existe por lo menos un art Con Categoria 'Acero INOX' que no tenga especificado un certificado                
			IF  (SELECT                 
					COUNT(d.Articulo)                
				FROM                
					CompraD d                  
				JOIN Art a ON d.Articulo = a.Articulo                 
				LEFT OUTER JOIN SerieloteMov sm ON d.Articulo = sm.Articulo                  
												AND ISNULL(RTRIM(LTRIM(d.SubCuenta)),'') =  ISNULL(RTRIM(LTRIM(sm.SubCuenta)),'')                
												AND 'COMS' = sm.Modulo                
												AND d.Id = sm.ID                
				WHERE                
					d.Id = @ID                
				AND (a.Categoria = 'Acero Inox' OR (a.Categoria = 'ALUMINIO' AND a.Grupo IN('PERFIL','PLACA','LAMINA','ROLLO LAMINA')))          
				AND NULLIF(sm.Certificado,'') IS NULL) > 0                
			BEGIN                
			SELECT @Ok  = 99930, @OkRef= 'Falta Especificar Ruta Certificado'                
			END                            
		END                

		/**Fin Modificacion Kike SIerra 13/06/2013*/                
		--Z.G. 15 07 2009 modificacion para que no envien al concepto equivocado                  
		DECLARE @ProveedorTipo varchar(15), @Categoria varchar(50),@concepto varchar(50)                  
                    
		SELECT @ProveedorTipo=p.Tipo,@Categoria=isnull(p.Categoria,'') ,@Concepto=isnull(c.concepto,'')                  
		FROM Prov p, compra c WHERE p.Proveedor =c.proveedor                  
		and c.id=@ID                  
                    
                    
		IF ltrim(rtrim(@Concepto)) = ''                  
			SELECT @Ok =20481 ,@OkRef='Se requiere concepto para poder contabilizar'                  
		ELSE IF ltrim(rtrim(@Concepto)) = 'Compras Nac' AND  @Categoria='Proveedores Import'                  
			SELECT @Ok =20481, @OkRef='Concepto no autorizado para ese proveedor'                  
		ELSE IF ltrim(rtrim(@Concepto)) = 'Compras Intern' AND  @Categoria='Proveedores Nac'                  
			SELECT @Ok =20481 ,@OkRef='Concepto no autorizado para ese proveedor'         
      
    --Carlos Orozco: 28/04/2016: Validación Para Ordenes de Compra Con Artículos Obsoletos o de Lento Movimiento
	  EXEC CUP_spValidaRotacionArt @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT
                                   
	END                

                 
               
                   
	--Kike Sierra: 14/08/2013: Valida los flujos de los movimientos de Compra                
	EXEC spCuprumFlujosCompra @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
                
	--Kike Sierra: 11/02/2014:  Procedimiento almacenado encargado de validar que en una Requisicion solamente se use un centro de costos.              
	EXEC spCuprumValidaCentroCReq @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
                 
                    
	--Kike Sierra: 28/08/2013: Evita que se Afecten Movimientos en Compra donde en el Detalle Exista algun articulo DESCONTINUADO con "SeCompra" en su planeacion = 0.                
	EXEC spCuprumArtNoCompraDescontinuados @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
    
	--Kike Sierra: 23/09/2014: Validaciones Simple del modulo de compras que no requieren un procedimiento dedicado.      
	EXEC spCuprumValidacionesSimplesComs @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT     

	--Carlos Orozco 22/04/2016: Validar Ordenes de Compra IMMEX a Almacenes IMMEX
	IF @Modulo='COMS' AND @MovClave='COMS.O' AND @Concepto = 'Compras IMMEX'
		BEGIN
			SELECT 
				@Almacen = Almacen 
			FROM Compra 
			WHERE ID=@ID
		
			IF @Almacen NOT LIKE 'IMEX%'
				SELECT @Ok=99995, @OkRef='Para Compras IMMEX Debes Seleccionar Un Almacen IMMEX'
		END

--mzunigaf  Septiembre 2016: Validar Ordenes de el proveedor CUPRUM PERFILES #N340 no estén en Dlls
--Ticket 018415, Chantty
DECLARE @Moneda varchar (10),
				@Proveedor varchar (10)

	IF @Modulo='COMS' AND @MovClave='COMS.O'
		BEGIN
			SELECT 
				@Moneda = Moneda,
				@Proveedor = Proveedor

			FROM Compra 
			WHERE ID=@ID
		
			IF @Moneda = 'Dlls' and @Proveedor='N340' and @GenerarMov <> 'Compra Perdida'
				SELECT @Ok=99995, @OkRef='No se pueden afectar OC de este Proveedor con Moneda Dlls'
		END
         
 
	--mzunigaf  Mayo 2016: Validar que tenga capturado CuprumFactura
	IF @Modulo='COMS' and @Estatus = 'SINAFECTAR' AND LTRIM(RTRIM(@MovClave)) IN ('COMS.B','COMS.D')
		BEGIN
			IF ISNULL (( SELECT CuprumFactura
			FROM Compra 
			WHERE ID=@ID),'')=''
			BEGIN
				SELECT @Ok=99995, @OkRef='No tiene informacion capturada de Nota de Credito en el campo Documento'
			END
		END




  /*FIN COMPRAS*/              
                
        
                 
	 /*Apartado Ventas */                
	 IF @Modulo = 'VTAS'                
	 BEGIN                
	   --Kike Sierra: 02/10/2013: Procedimiento que valida que no este duplicada la Orden de Compra en los Movimientos de Venta.                
	  EXEC spCuprumValidaVtaOrdenC @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
              
	   --Kike Sierra: 14/08/2013: Valida los flujos de los movimientos de Venta              
	  EXEC spCuprumFlujosVenta @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT              
         
	   --Kike Sierra: 13/06/2014: Valida las Cantidades a afectar de un pedido al generar una orden surtido.        
	   EXEC spCuprumValidaCantPedidoAOrdenS @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT 
  
		--Kike Sierra: 17/06/2014: Validaciones Simple del modulo de ventas que no requieren un procedimiento dedicado.        
	   EXEC spCuprumValidacionesSimplesVtas @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT       
	   
	   	--Kike Sierra: 13/04/2015: Valida la afectacion de movimientos de Venta Perdida.        
	   EXEC spCuprumValidaVtaPerdida @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT            
     
    --Kike Sierra: 09/OCT/2015: Validaciones Vena Mostrador
    IF ISNULL(@CUP_VtaMostrador,0) = 1 
BEGIN 
	   EXEC CUP_SPP_ValidaVtaMost @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT   
    END 
    --
	 END                    
 
	 /*Apartado PROD */        
	 IF @Modulo = 'PROD'              
	 BEGIN              
		--Kike SIerra: 11/12/2013: Valida que el Almacen de Una Orden de Produccion Sea igual a los de su detalle y su Programa              
		EXEC spCuprumValidaAlmacenOrdenProd @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
	 END              
                
	 IF @Modulo = 'CXP'              
	 BEGIN              

		 --Kike SIerra: 18/12/2013: Valida que la Referencia en los movimientos de CXP(Se creo con inicio en el desarrollo DE              
		 --Aplicaciones automaticas de Anticipos a ordenes Prod)              
		 EXEC spCuprumValidaCxpReferencia @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT
		 
		  /* Kike Sierra: 24/03/2015: Validaciones Contabilidad Electrónica*/
      Exec spCMLContaEValidaAntesAfectar @Modulo,@ID, @Mov,@MovClave,@Estatus,@Accion,@Base,@GenerarMov,@Usuario, @Ok OUTPUT,  @OkRef OUTPUT               
	 END                  
                 
	 /****************Apartado VARIOS ***************/                  
	--Kike Sierra: 01/10/2013: Procedimiento que valida Caracteres Especiales en los consecutivos de los  Modulos de Compra y Gastos                
	EXEC spCuprumValidaCaracteresEspMovId @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
                 
	/*Multiples Modulos, incluir procedimientos que apliquen sin importar el modulo o bien hagan la validacion dentro del mismo procedimiento.*/                
	--Kike Sierra: 27/09/2013: Procedimiento que valida la AFectacion de movimientos que formen parte del procesp de "PEDIDO-TRASPASOS AUTOMATICOS".                
	EXEC spCuprumValidaPedidoTraspasosAuto @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
               
	--Kike SIerra:27/11/2013: Valida que el Almacen no este Bloqueado por la Toma de Inventarios.              
	EXEC spCuprumAlmacenBloqueado @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
               
     
                  
----Kike Sierra: 01/04/2014: Valida los flujos en relacion a las Facturas Anticipo creadas y aplicadas de forma automatica con un pedido ligado.              
--  EXEC spCuprumValidaFlujoFacturasAntAuto @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT              
              
      
	/*Kike Sierra 20/06/2014: Procedimiento Almacenado encargado de validar que no se dpuedan afectar movimientos donde        
	el Modulo este Bloqueado para el Almacen */            
	EXEC spCuprumValidaInvAlmacenesBloqueados @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT              
              
	--Kike Sierra: 01/07/2014:  Validar que no se introduzcan facturas duplicadas en los modulos de compras y gastos.        
	EXEC spCuprumValidaFacturaComsGas @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT                
               
      
      /******************************** APARTADO GASTOS ****************************/        
	IF @modulo = 'GAS'      
	BEGIN   
		--Kike Sierra: 05/08/2014: Valida los flujos de los movimientos de Gastos              
		EXEC spCuprumFlujosGasto @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT    
          
          
          --mzunigaf  Mayo 2016: Validar que tenga capturado CuprumFactura
          IF @Estatus = 'SINAFECTAR' 
          AND LTRIM(RTRIM(@MovClave)) = 'GAS.DG'
          BEGIN
              IF ISNULL((SELECT CuprumFactura
                         FROM Gasto 
                         WHERE ID=@ID),'')=''
              BEGIN
	             SELECT @Ok=99995, @OkRef='No tiene informacion capturada de Nota de Credito'
              END
          END	           
	END      
     
     /******************************* FIN APARTADO GASTOS ***************************/     
    
	--select CuprumFactura from gasto 

	
--	END     

	    
        
        
	--/* Omar chávez Valida la forma de cobro en ventas */  
	--IF @modulo ='VTAS' AND (Select MovTipo.Clave From Venta, MovTipo Where MovTipo.Modulo='VTAS' And MovTipo.Mov=Venta.Mov And Venta.ID=@ID) In('VTAS.F','VTAS.B', 'VTAS.D')  
	--Begin  
	--	IF (Select Ltrim(Rtrim(Isnull(Venta.Formapagotipo,''))) From Venta Where Venta.ID=@ID)=''  
	--	Begin  
	--		SELECT @Ok =10010 ,@OkRef='Se requiere La Forma de Pago'   
	--	End   
       
	--End          
        
        
	--/* Omar chávez 08/01/2015 Valida la Serielote que no tenga caracteres invalidos */         
	--/* MZUNIGAF 4-Abr-2016 Se habilitó */
	IF  @MovClave In ('COMS.EG','COMS.EI','COMS.F','INV.E','INV.A','PROD.E','VTAS.D','VTAS.DC')
	Begin
		Exec spCuprumValidaSLCaracter  @ID, @Modulo, @Ok Output,  @OkRef Output
	End       


	/* Omar chávez 09/01/2015 Valida la Serielote que no tenga mas de 20 caracteres */         
	IF  @MovClave In ('COMS.EG','COMS.EI','COMS.F','INV.A','INV.E','PROD.E','VTAS.D','VTAS.DC')
	Begin
	  Exec spCuprumSLMaxCaracter  @ID, @Modulo, @Ok Output,  @OkRef Output
	End    

	--/* Omar chávez 14/01/2015 Valida la Referencia que no tenga caracteres invalidos */         
	IF  @MoDulo In ('COMS','CXP','GAS')
	Begin
	  Exec spCuprumValidaRefCaracter  @ID, @Modulo, @Ok Output,  @OkRef Output
	End      

     
	--Kike SIerra 25/03/2014: Procedimiento Almacenado que Valida que los movimientos en Compras o Ventas por concepto de IMEX, cumplan con las caracterisitcas Requeridas:
	EXEC spCuprumValidaMovimientosIMEX @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT  
  
	--  --Kike Sierra: 04/09/2013: Procedimiento que valida la AFectacion de un Embarque                
	EXEC spCuprumValidaAfectacionEmbarque @Modulo,@ID,@Accion,@Base,@GenerarMov,@Usuario,@Ok OUTPUT,@OkRef OUTPUT     
	        
  --Kike Sierra: 16/07/2014: Validaciones del Desarrollo de Datos Cliente Mostrador.        
  EXEC spCuprumVtasCteMostrador @Modulo,@ID,'VALIDAR',NULL,@Ok OUTPUT,@OkRef OUTPUT  


  IF @Ok  IS NULL 
  AND @Modulo = 'DIN'
  BEGIN
    --Kike Sierra: 18/OCT/2015: Se agrego la siguiente validacion para verificar los importes de los 
    -- Cortes Parciales Multimoneda.
    EXEC CUP_spp_DinValidarSaldoAlCorte 
      @Empresa,
      @Modulo,    
      @ID, 
      @Estatus,
      @Mov,
      @MovClave,
      @SubClave,
      @CtaDinero,
      @Accion,           
      @Usuario,       
      @Ok OUTPUT ,        
      @OkRef  OUTPUT
     --
  END  

  --Kike Sierra: 07/MAR/2016
  /** Validaciones CFDI ***/
    EXEC CUP_SPP_CFDIValidaAntesAfectar 
      @Modulo,
@ID,
   @Estatus,
      @Mov,
      @MovClave,
      @Accion,
      @Base,
      @GenerarMov,
      @Usuario,
      @Ok OUTPUT,
      @OkRef OUTPUT         
  /** FIN Validaciones CFDI*/
                 
	RETURN                
END                      