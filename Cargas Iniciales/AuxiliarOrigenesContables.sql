TRUNCATE TABLE CUP_CxOrigenContable

INSERT INTO 
  CUP_CxOrigenContable
(
  AuxModulo,
  AuxMov,
  Modulo,
  Mov,
  ValidarOrigen,
  OrigenTipo,
  Origen
)
VALUES
('CXP', 'Ajuste', 'CXP', 'Ajuste', 0, NULL, NULL),
('CXP', 'Ajuste Redondeo', 'CXP', 'Ajuste Redondeo', 0, NULL, NULL),
('CXP', 'Ajuste Saldo', 'CXP', 'Ajuste Saldo', 0, NULL, NULL),
('CXP', 'Anticipo', 'CXP', 'Anticipo', 0, NULL, NULL),
('CXP', 'Aplicacion', 'CXP', 'Aplicacion', 0, NULL, NULL),
('CXP', 'Cargo Proveedor' , 'CXP', 'Cargo Proveedor', 0, NULL, NULL),
('CXP', 'Cargo Proveedor IVA', 'CXP', 'Cargo Proveedor IVA', 0, NULL, NULL),
('CXP', 'Conversion Cargo', 'CXP', 'Conversion Cargo', 0, NULL, NULL),
('CXP', 'Conversion Credito', 'CXP', 'Conversion Credito', 0, NULL, NULL),
('CXP', 'Correccion Rebate', 'CXP', 'Correccion Rebate', 0, NULL, NULL),
('CXP', 'Credito Proveedor', 'CXP', 'Credito Proveedor', 1, NULL, NULL),
('CXP', 'Credito Proveedor', 'COMS', 'Devolucion Compra', 0, NULL, NULL),
('CXP', 'Credito Proveedor', 'COMS', 'Bonificacion Compra', 0, NULL, NULL),
('CXP', 'Cheque Devuelto', 'CXP', 'Cheque Devuelto', 0, NULL, NULL),
('CXP', 'Devol Insumo', 'COMS', 'Devol Insumo', 0, NULL, NULL),
('CXP', 'Devol Servicio', 'COMS', 'Devol Servicio', 0, NULL, NULL),
('CXP', 'Devolucion', 'CXP', 'Devolucion', 0, NULL, NULL),
('CXP', 'Devolucion Gasto', 'CXP', 'Devolucion Gasto', 1, NULL, NULL),
('CXP', 'Devolucion Gasto', 'GAS', 'Devolucion Gasto', 0, NULL, NULL),
('CXP', 'Devolucion Retencion', 'CXP', 'Devolucion Retencion', 0, NULL, NULL),
('CXP', 'Endoso a Favor', 'CXP', 'Endoso a Favor', 0, NULL, NULL),
('CXP', 'Entrada Compra', 'COMS', 'Entrada Compra', 0, NULL, NULL),
('CXP', 'Entrada con Gastos', 'COMS', 'Entrada con Gastos', 0, NULL, NULL),
('CXP', 'Entrada Insumo', 'COMS', 'Entrada Insumo', 0, NULL, NULL),
('CXP', 'Entrada Maquila', 'COMS', 'Entrada Maquila', 0, NULL, NULL),
('CXP', 'Entrada Maquila Fund', 'COMS', 'Entrada Maquila Fund', 0, NULL, NULL),
('CXP', 'Entrada Servicio', 'COMS', 'Entrada Servicio', 0, NULL, NULL),
('CXP', 'Gasto', 'GAS', 'Gasto', 1, NULL, NULL),
('CXP', 'Gasto Prorrateado', 'GAS', 'Gasto', 1, 'GAS', 'Gasto Prorrateado'),
('CXP', 'Gastos Fletes', 'GAS', 'Gastos Fletes', 0, NULL, NULL),
('CXP', 'Gastos Generales', 'GAS', 'Gastos Generales', 0, NULL, NULL),
('CXP', 'Pago', 'CXP', 'Pago', 0, NULL, NULL),
('CXP', 'Prestamo', 'CXP', 'Prestamo', 0, NULL, NULL),
('CXP', 'Retencion', 'CXP', 'Retencion', 0, NULL, NULL),
('CXP', 'Reevaluacion', 'CXP', 'Reevaluacion', 0, NULL, NULL),
('CXP', 'Reevaluacion Credito', 'CXP', 'Reevaluacion Credito', 0, NULL, NULL)

SELECT
  ID,
  AuxModulo,
  AuxMov,
  Modulo,
  Mov,
  ValidarOrigen,
  OrigenTipo,
  Origen
FROM
  CUP_CxOrigenContable
ORDER BY
  ID