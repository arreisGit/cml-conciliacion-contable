TRUNCATE TABLE CUP_CxRelacionAuxiliarModulo

INSERT INTO 
  CUP_CxRelacionAuxiliarModulo
(
  AuxModulo,
  AuxMov,
  Modulo,
  Mov
)
VALUES
('CXP','Ajuste Redondeo','CXP','Ajuste Redondeo'),
('CXP','Aplicacion','CXP','Aplicacion'),
('CXP','Correccion Rebate','CXP','Correccion Rebate'),
('CXP','Credito Proveedor','CXP','Credito Proveedor'),
('CXP','Credito Proveedor','COMS','Devolucion Compra'),
('CXP','Credito Proveedor','COMS','Bonificacion Compra'),
('CXP','Devolucion Gasto','CXP','Devolucion Gasto'),
('CXP','Entrada Compra','CXP','Entrada Compra'),
('CXP','Entrada Maquila','CXP','Entrada Maquila'),
('CXP','Ajuste Saldo','CXP','Ajuste Saldo'),
('CXP','Anticipo','CXP','Anticipo'),
('CXP','Devolucion Retencion','CXP','Devolucion Retencion'),
('CXP','Entrada con Gastos','CXP','Entrada con Gastos'),
('CXP','Pago','CXP','Pago'),
('CXP','Retencion','CXP','Retencion'),
('CXP','Ajuste','CXP','Ajuste'),
('CXP','Cargo Proveedor','CXP','Cargo Proveedor'),
('CXP','Cargo Proveedor IVA','CXP','Cargo Proveedor IVA'),
('CXP','Devol Insumo','CXP','Devol Insumo'),
('CXP','Devolucion','CXP','Devolucion'),
('CXP','Entrada Insumo','CXP','Entrada Insumo'),
('CXP','Gastos Fletes','CXP','Gastos Fletes'),
('CXP','Devol Servicio','CXP','Devol Servicio'),
('CXP','Entrada Servicio','CXP','Entrada Servicio'),
('CXP','Gasto Prorrateado','GAS','Gasto'),
('CXP','Gastos Generales','CXP','Gastos Generales'),
('CXP','Reevaluacion','CXP','Reevaluacion'),
('CXP','Reevaluacion Credito','CXP','Reevaluacion Credito')

SELECT
  ID,
  AuxModulo,
  AuxMov,
  Modulo,
  Mov
FROM
  CUP_CxRelacionAuxiliarModulo
ORDER BY
  ID