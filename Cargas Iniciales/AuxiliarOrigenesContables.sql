TRUNCATE TABLE CUP_CxOrigenContable

INSERT INTO 
  CUP_CxOrigenContable
(
  AuxModulo,
  AuxMov,
  Modulo,
  Mov,
  Factor,
  UsarAuxiliarNeto,
  ValidarOrigen,
  OrigenTipo,
  Origen
)
VALUES
  ('CXP', 'Ajuste',               'CXP',  'Ajuste',                1, 0, 0, NULL,  NULL),
  ('CXP', 'Ajuste Redondeo',      'CXP',  'Ajuste Redondeo',       1, 0, 0, NULL,  NULL),
  ('CXP', 'Ajuste Saldo',         'CXP',  'Ajuste Saldo',          1, 0, 0, NULL,  NULL),
  ('CXP', 'Anticipo',             'CXP',  'Anticipo',             -1, 0, 0, NULL,  NULL),
  ('CXP', 'Aplicacion',           'CXP',  'Aplicacion',            1, 1, 0, NULL,  NULL),
  ('CXP', 'Cargo Proveedor' ,     'CXP',  'Cargo Proveedor',       1, 0, 0, NULL,  NULL),
  ('CXP', 'Cargo Proveedor IVA',  'CXP',  'Cargo Proveedor IVA',   1, 0, 0, NULL,  NULL),
  ('CXP', 'Conversion Cargo',     'CXP',  'Conversion Cargo',     -1, 0, 0, NULL,  NULL),
  ('CXP', 'Conversion Credito',   'CXP',  'Conversion Credito',    1, 0, 0, NULL,  NULL),
  ('CXP', 'Correccion Rebate',    'CXP',  'Correccion Rebate',     1, 0, 0, NULL,  NULL),
  ('CXP', 'Credito Proveedor',    'CXP',  'Credito Proveedor',    -1, 0, 1, NULL,  NULL),
  ('CXP', 'Credito Proveedor',    'COMS', 'Devolucion Compra',    -1, 0, 0, NULL,  NULL),
  ('CXP', 'Credito Proveedor',    'COMS', 'Bonificacion Compra',  -1, 0, 0, NULL,  NULL),
  ('CXP', 'Cheque Devuelto',      'CXP',  'Cheque Devuelto',       1, 0, 0, NULL,  NULL),
  ('CXP', 'Devol Insumo',         'COMS', 'Devol Insumo',         -1, 0, 0, NULL,  NULL),
  ('CXP', 'Devol Servicio',       'COMS', 'Devol Servicio',       -1, 0, 0, NULL,  NULL),
  ('CXP', 'Devolucion',           'CXP',  'Devolucion',            1, 0, 0, NULL,  NULL),
  ('CXP', 'Devolucion Gasto',     'CXP',  'Devolucion Gasto',     -1, 0, 1, NULL,  NULL),
  ('CXP', 'Devolucion Gasto',     'GAS',  'Devolucion Gasto',     -1, 0, 0, NULL,  NULL),
  ('CXP', 'Devolucion Retencion', 'CXP',  'Devolucion Retencion', -1, 0, 0, NULL,  NULL),
  ('CXP', 'Endoso a Favor',       'CXP',  'Endoso a Favor',        1, 1, 0, NULL,  NULL),
  ('CXP', 'Entrada Compra',       'COMS', 'Entrada Compra',        1, 0, 0, NULL,  NULL),
  ('CXP', 'Entrada con Gastos',   'COMS', 'Entrada con Gastos',    1, 0, 0, NULL,  NULL),
  ('CXP', 'Entrada Insumo',       'COMS', 'Entrada Insumo',        1, 0, 0, NULL,  NULL),
  ('CXP', 'Entrada Maquila',      'COMS', 'Entrada Maquila',       1, 0, 0, NULL,  NULL),
  ('CXP', 'Entrada Maquila Fund', 'COMS', 'Entrada Maquila Fund',  1, 0, 0, NULL,  NULL),
  ('CXP', 'Entrada Servicio',     'COMS', 'Entrada Servicio',      1, 0, 0, NULL,  NULL),
  ('CXP', 'Gasto Prorrateado',    'GAS',  'Gasto',                 1, 0, 0, NULL,  NULL),
  ('CXP', 'Gastos Fletes',        'GAS',  'Gastos Fletes',         1, 0, 0, NULL,  NULL),
  ('CXP', 'Gastos Generales',     'GAS',  'Gastos Generales',      1, 0, 0, NULL,  NULL),
  ('CXP', 'Pago',                 'CXP',  'Pago',                 -1, 0, 0, NULL,  NULL),
  ('CXP', 'Prestamo',             'CXP',  'Prestamo',              1, 0, 0, NULL,  NULL),
  ('CXP', 'Retencion',            'CXP',  'Retencion',             1, 0, 0, NULL,  NULL),
  ('CXP', 'Reevaluacion',         'CXP',  'Reevaluacion',          1, 0, 0, NULL,  NULL),
  ('CXP', 'Reevaluacion Credito', 'CXP',  'Reevaluacion Credito',  1, 0, 0, NULL,  NULL)

SELECT
  ID,
  AuxModulo,
  AuxMov,
  Modulo,
  Mov,
  Factor,
  UsarAuxiliarNeto,
  ValidarOrigen,
  OrigenTipo,
  Origen
FROM
  CUP_CxOrigenContable
ORDER BY
  ID