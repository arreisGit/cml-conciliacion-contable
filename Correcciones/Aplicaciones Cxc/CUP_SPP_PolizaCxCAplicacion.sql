-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alejandra Camarena Barrón
-- Create date: 18/01/2016
-- Description:	Póliza de 
-- =============================================
ALTER PROCEDURE [dbo].[CUP_SPP_PolizaCxCAplicacion] 
	  @ID       int,
	  @Modulo		char(10)
AS
BEGIN
DECLARE 
	@ImporteIVA FLOAT 

	Select (sum(factor* (dc.importe*c.ivafiscal)*dc.tipocambiooriginal))*-1 
	From CUP_v_CxDiferenciasCambiarias dc 
	Join Cxc c on c.Mov = dc.Documento and c.MovId = dc.DocumentoId 
	Where dc.moduloid = @ID
	AND dc.modulo = @Modulo
	
	-- SELECT @ImporteIVA
END