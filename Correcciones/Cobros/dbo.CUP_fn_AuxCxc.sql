USE [Cuprum]
GO
/****** Object:  UserDefinedFunction [dbo].[CUP_fn_AuxCxc]    Script Date: 3/23/2017 9:00:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Created by:    Alejandra Camarena
-- Creation Date: 2017-03-15
-- Last Modified: 2017-03-15 
--
-- Description: Funcion encargada de regresar el un bit para identificar si es cobro de caja chica.
-- 
-- Example:       SELECT dbo.CUP_fn_AuxCxc('CXC', 483822, '0', 'CXC')
-- SELECT dbo.CUP_fn_AuxCxc(474379)
-- =============================================

ALTER FUNCTION [dbo].[CUP_fn_AuxCxc]
( 
  @Modulo char(10),
  @ID int,
  @Saldo char(1),
  @Rama char(10)
)
RETURNS INT
AS BEGIN

	DECLARE 
    @Impuestos float
    IF @Saldo = '0'
  BEGIN  
 	SELECT 
    @Impuestos = sum((Neto * IVAFiscal)*TipoCambio) 
  FROM CUP_v_AuxiliarCxc
  WHERE 
    Modulo = @Modulo
      AND Moduloid = @ID
      AND Rama = @Rama
      AND Aplica NOT IN ('SALDO A FAVOR','SALDOS CTE', 'NOTA CARGO IVA CXC')
  END
  ELSE 
	SELECT 
    @Impuestos = sum((Neto * IVAFiscal)* TipoCambio) 
  FROM CUP_v_AuxiliarCxc
  WHERE 
    Modulo = @Modulo
      AND Moduloid = @ID
      AND Rama = @Rama
      AND Aplica IN ('SALDO A FAVOR','SALDOS CTE', 'NOTA CARGO IVA CXC')
	
  RETURN @Impuestos

END

