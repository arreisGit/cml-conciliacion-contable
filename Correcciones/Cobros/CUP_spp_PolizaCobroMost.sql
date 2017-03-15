USE [Cuprum]
GO
/****** Object:  StoredProcedure [dbo].[CUP_spp_PolizaCobroMost]    Script Date: 03/01/2017 04:05:36 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*Ejemplo Llamado
DECLARE
  @OK INT,
  @OKRef VARCHAR(255) 

  EXEC CUP_spp_PolizaCobroMost
    @PolizaID = 728593, 
    @Modulo = 'CXC',
    @ModuloID =  359445,
    @Ok = @OK OUTPUT,
    @OkRef = @OkRef OUTPUT

  SELECT Ok = @OK, OkRef = @OkRef

*/

      
/********************** CREACION DEL PROCEDIMIENTO *********************************************************/      
ALTER PROCEDURE [dbo].[CUP_spp_PolizaCobroMost]
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
    @Mov CHAR(20),
    @MovTipo CHAR(20),
    @Moneda CHAR(20),
    @TipoCambio FLOAT,
    @HOY DATE = GETDATE(),
    @MaxRenglon FLOAT,
    --
    @CtaClientesContado CHAR(20) = '113-406-000-0000',
    @CtaCajaChica CHAR(20),
    @CtaCajaChicaDesc VARCHAR(50),
    @ImporteTotalMN DECIMAL(19,4),
    @Fecha DATE,
    @FormaCobro VARCHAR(50),
    @ConDesglose BIT = 0,

	@CtaConcepto CHAR (20),
	@CtaPerdida CHAR(20) = '740-200-000-0000',
	@CtaUtilidad CHAR(20) = '740-100-000-0000'
 
  PRINT('CUP_spp_PolizaCobroMost')

  IF @Modulo = 'CXC'
  BEGIN
    --Obtenemos los datos del Cobro.
    SELECT  
      @Empresa = c.Empresa,
      @Sucursal = c.Sucursal,
      @Estatus = c.Estatus,
      @Mov = c.Mov,
      @Movtipo  = t.Clave,
      @ImporteTotalMN = ROUND((ISNULL(c.Importe,0) + ISNULL(c.Impuestos,0) - ISNULL(c.Retencion,0) - ISNULL(c.Retencion2,0) - ISNULL(c.Retencion3,0)) * c.TipoCambio ,4),
      @CtaCajaChica = cd.Cuenta,
      @CtaCajaChicaDesc = cd.Descripcion,
      @Fecha = c.FechaEmision,
      @FormaCobro = c.FormaCobro,
      @ConDesglose = c.ConDesglose
    FROM
      Cxc c  
    JOIN MovTipo t ON @Modulo = t.Modulo
                    AND c.Mov = t.Mov
    LEFT JOIN Agente a ON c.Cajero = a.Agente
    JOIN CtaDinero cD ON a.CUP_DefCtaDinero = cD.CtaDinero
    WHERE 
      c.Id = @ModuloID

    -- Validamos si se trata de un Cobro Mostrador
    IF ((EXISTS(SELECT 
                mf.OID
              FROM 
                dbo.fnCMLMovFlujo(@Modulo,@ModuloID,0) mf
              JOIN Venta v ON mf.OID = v.ID 
              WHERE 
                mf.Indice < 0
              AND mf.OModulo = 'VTAS'
              AND mf.OMovTipo = 'VTAS.F'
              AND ISNULL(v.CUP_VtaMostrador,0) = 1)
    AND @Mov = 'Cobro')
    OR (@Mov = 'Cobro Anticipo' AND ISNULL(@FormaCobro,'') = 'Caja Chica' AND ISNULL(@ConDesglose,0) = 1))
    AND @MovTipo = 'CXC.C' 
    AND @Estatus IN ('CONCLUIDO','CANCELADO')
    BEGIN 
      DELETE ContD WHERE ID = @PolizaID 
      
      DECLARE @Poliza TABLE 
      (
        Cuenta CHAR(20) NOT NULL,
        Debe DECIMAL(19,4) NULL,
        Haber DECIMAL(19,4) NULL,
        Concepto VARCHAR(50) NULL, 
        Orden INT NULL
      )
	  -- obtenemos la cuenta del concepto
      SELECT @CtaConcepto = c.cuenta FROM CXC JOIN Concepto C on C.Concepto = Cxc.COncepto WHERE CXC.ID =  @ModuloID 

      INSERT INTO  @Poliza (Cuenta,Debe,Haber,Concepto,Orden)
      SELECT ISNULL(@CtaClientesContado,''), NULL , @ImporteTotalMN, 'Clientes Contado', 1
      UNION 
      SELECT ISNULL(@CtaCajaChica,''), @ImporteTotalMN ,NULL,LEFT(@CtaCajaChicaDesc,50), 2
	  
	IF (SELECT SUM(Diferencia_Cambiaria_MN) FROM CUP_v_CxDiferenciasCambiarias WHERE ModuloID=@ModuloID AND Modulo='CXC')>0
		  INSERT INTO  @Poliza (Cuenta,Debe,Haber,Concepto,Orden)
		  SELECT ISNULL(@CtaUtilidad,''),NULL,ABS(SUM(Diferencia_Cambiaria_MN)),'Utilidad Cambiaria', 3
		  FROM  CUP_v_CxDiferenciasCambiarias WHERE ModuloID=@ModuloID AND Modulo='CXC'
		  UNION 
		  SELECT ISNULL(@CtaClientesContado,''),ABS(SUM(Diferencia_Cambiaria_MN)),NULL,'Utilidad Cambiaria', 4
		  FROM  CUP_v_CxDiferenciasCambiarias WHERE ModuloID=@ModuloID AND Modulo='CXC'

	IF (SELECT SUM(Diferencia_Cambiaria_MN) FROM CUP_v_CxDiferenciasCambiarias WHERE ModuloID=@ModuloID AND Modulo='CXC')<0
		  INSERT INTO  @Poliza (Cuenta,Debe,Haber,Concepto,Orden)
		  SELECT ISNULL(@CtaPerdida,''),ABS(SUM(Diferencia_Cambiaria_MN)),NULL,'Perdida Cambiaria', 5
		  FROM  CUP_v_CxDiferenciasCambiarias WHERE ModuloID=@ModuloID AND Modulo='CXC'
		  UNION 
		  SELECT ISNULL(@CtaClientesContado,''),NULL,ABS(SUM(Diferencia_Cambiaria_MN)),'Perdida Cambiaria', 6
		  FROM  CUP_v_CxDiferenciasCambiarias WHERE ModuloID=@ModuloID AND Modulo='CXC'

      --Inserta la Poliza del Cobro Mostrador.
      IF ISNULL(@ImporteTotalMN,0) > 0
      BEGIN
       
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
          Renglon =  CAST(2048 * ROW_NUMBER() OVER (ORDER BY pol.Orden) AS FLOAT),   
          RenglonSub = 0, 
          Cuenta = pol.Cuenta,
          Subcuenta = NULL, 
          Concepto = pol.Concepto,
          Debe = pol.Debe,
          Haber = pol.Haber,
          Empresa = @Empresa,
          Ejercicio = YEAR(@Fecha),
          Periodo = MONTH(@Fecha),
          FechaContable = @Fecha,
          Sucursal = @Sucursal,
          SucursalContable = @Sucursal,
          SucursalOrigen = @Sucursal
        FROM 
          @Poliza pol        
        WHERE 
          ROUND(ISNULL(pol.Debe,0),2) <> 0
        OR ROUND(ISNULL(pol.Haber,0),2) <> 0
        ORDER BY 
          pol.Orden
          
      END
      ELSE BEGIN
        INSERT INTO  @Poliza  (Cuenta,Debe,Haber,Concepto,Orden)
        SELECT 'Error', NULL , 0, 'Error Generacion Póliza',1
      END 

      
      IF @Estatus = 'CANCELADO'
      BEGIN
        UPDATE ContD SET Debe = Debe * -1 , Haber = Haber * -1  WHERE ID = @PolizaID
      END

    END 
  END 

  RETURN      
END  TRY 
BEGIN CATCH
  SELECT @OkREf  = ERROR_MESSAGE()
END CATCH




