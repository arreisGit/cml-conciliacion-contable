GO
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER OFF
GO


IF EXISTS (SELECT id FROM sysobjects WHERE id = object_id('CUP_spp_ValidacionesSimplesCxc') AND type = 'P') 
	DROP PROCEDURE CUP_spp_ValidacionesSimplesCxc
GO


/* =============================================
 Created by:    Alejandra Camarena
 Creation Date: 2017-01-04
 
 Description: Procedimiento encargado de llevar un
 control de las validaciones simples CXC que por su
 tamaño o naturaleza no necesitan de un stored procedure
 dedicado.

 ============================================= */

CREATE PROCEDURE CUP_spp_ValidacionesSimplesCxc
										@Modulo      char(5),
                    @ID          int,  
                    @Mov         CHAR(20),
                    @MovTipo     CHAR(20),
                    @Accion      char(20),  
                    @Base        char(20),  
                    @GenerarMov  char(20),  
                    @Usuario     char(10),  
                    @Ok          int          OUTPUT,  
                    @OkRef       varchar(255)  OUTPUT
AS BEGIN

  IF @Modulo = 'CXC'	
  AND @Accion IN('VERIFICAR','AFECTAR','GENERAR')
  BEGIN
    DECLARE
      @Estatus VARCHAR(15),
      @FechaEmision DATETIME

    SELECT 
      @Estatus = Estatus,
      @FechaEmision = FechaEmision
    FROM  
      Cxc
    WHERE 
      ID = @ID
	  
	  IF @MovTipo = 'CXC.C'
	  BEGIN
      -- Valida que no se puedan aplicar cobros con diferente tipo de cambio
      -- de las facturass anticipo
      IF 
          EXISTS(
                SELECT 
                  cobroD.Aplica
                FROM 
                  Cxc cobro 
                JOIN CxcD cobroD ON cobroD.ID = cobro.ID
                JOIN Movtipo aplicaTipo ON aplicaTipo.Modulo = 'CXC'
                                        AND aplicaTipo.Mov = cobroD.Aplica
                JOIN Cxc doc ON doc.Mov = cobroD.Aplica
                            AND doc.MovID = cobroD.AplicaID
                WHERE 
                  cobro.ID = @ID 
                AND aplicaTipo.Clave = 'CXC.FA'
                AND doc.TipoCambio <> cobro.ClienteTipoCambio
                ) 
      BEGIN
        SELECT @OK = 99946, @OKRef = 'No es posible afectar cobros con un tipo de cambio'
                                   + ' distinto al de su factura anticipo.' 
      END
    END      
    
    IF @MovTipo = 'CXC.FA'
    AND @Accion IN ('AFECTAR','GENERAR','VERIFICAR') 
    BEGIN
        
      IF @Estatus = 'SINAFECTAR'
      AND CAST(@FechaEmision AS DATE) <> CAST( GETDATE() AS DATE)
      BEGIN
        SELECT
          @OK = 99946,
          @OkRef = 'No es posible afectar facturas anticipo con una fecha emision distinta'
                 + ' a la actual.'
      END

    END
  END
  
  RETURN  
END