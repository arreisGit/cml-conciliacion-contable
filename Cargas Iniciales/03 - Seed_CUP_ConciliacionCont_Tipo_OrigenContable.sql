TRUNCATE TABLE CUP_ConciliacionCont_Tipo_OrigenContable

INSERT INTO 
  CUP_ConciliacionCont_Tipo_OrigenContable
(
  Tipo,
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
  --/* Saldos Proveedores */
  ( 1, 'CXP', 'Ajuste',               'CXP',  'Ajuste',                1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Ajuste Redondeo',      'CXP',  'Ajuste Redondeo',       1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Ajuste Saldo',         'CXP',  'Ajuste Saldo',          1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Anticipo',             'CXP',  'Anticipo',             -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Aplicacion',           'CXP',  'Aplicacion',            1, 1, 0, NULL,  NULL),
  ( 1, 'CXP', 'Cargo Proveedor' ,     'CXP',  'Cargo Proveedor',       1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Cargo Proveedor IVA',  'CXP',  'Cargo Proveedor IVA',   1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Conversion Cargo',     'CXP',  'Conversion Cargo',     -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Conversion Credito',   'CXP',  'Conversion Credito',    1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Correccion Rebate',    'CXP',  'Correccion Rebate',     1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Credito Proveedor',    'CXP',  'Credito Proveedor',    -1, 0, 1, NULL,  NULL),
  ( 1, 'CXP', 'Credito Proveedor',    'COMS', 'Devolucion Compra',    -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Credito Proveedor',    'COMS', 'Bonificacion Compra',  -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Cheque Devuelto',      'CXP',  'Cheque Devuelto',       1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Devol Insumo',         'COMS', 'Devol Insumo',         -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Devol Servicio',       'COMS', 'Devol Servicio',       -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Devolucion',           'CXP',  'Devolucion',            1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Devolucion Gasto',     'CXP',  'Devolucion Gasto',     -1, 0, 1, NULL,  NULL),
  ( 1, 'CXP', 'Devolucion Gasto',     'GAS',  'Devolucion Gasto',     -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Devolucion Retencion', 'CXP',  'Devolucion Retencion', -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Endoso a Favor',       'CXP',  'Endoso a Favor',        1, 1, 0, NULL,  NULL),
  ( 1, 'CXP', 'Entrada Compra',       'COMS', 'Entrada Compra',        1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Entrada con Gastos',   'COMS', 'Entrada con Gastos',    1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Entrada Insumo',       'COMS', 'Entrada Insumo',        1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Entrada Maquila',      'COMS', 'Entrada Maquila',       1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Entrada Maquila Fund', 'COMS', 'Entrada Maquila Fund',  1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Entrada Servicio',     'COMS', 'Entrada Servicio',      1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Gasto Prorrateado',    'GAS',  'Gasto',                 1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Gastos Fletes',        'GAS',  'Gastos Fletes',         1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Gastos Generales',     'GAS',  'Gastos Generales',      1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Pago',                 'CXP',  'Pago',                 -1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Prestamo',             'CXP',  'Prestamo',              1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Retencion',            'CXP',  'Retencion',             1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Reevaluacion',         'CXP',  'Reevaluacion',          1, 0, 0, NULL,  NULL),
  ( 1, 'CXP', 'Reevaluacion Credito', 'CXP',  'Reevaluacion Credito',  1, 0, 0, NULL,  NULL),
 -- /* IVA Por Acreeditar */
  ( 2, 'CXP', 'Anticipo',             'CXP',  'Anticipo',             -1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Aplicacion',           'CXP',  'Aplicacion',            1, 1, 0, NULL,  NULL),
  ( 2, 'CXP', 'Cargo Proveedor' ,     'CXP',  'Cargo Proveedor',       1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Credito Proveedor',    'CXP',  'Credito Proveedor',    -1, 0, 1, NULL,  NULL),
  ( 2, 'CXP', 'Credito Proveedor',    'COMS', 'Devolucion Compra',    -1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Credito Proveedor',    'COMS', 'Bonificacion Compra',  -1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Cheque Devuelto',      'CXP',  'Cheque Devuelto',       1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Devol Insumo',         'COMS', 'Devol Insumo',         -1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Devol Servicio',       'COMS', 'Devol Servicio',       -1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Devolucion',           'CXP',  'Devolucion',            1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Devolucion Gasto',     'CXP',  'Devolucion Gasto',     -1, 0, 1, NULL,  NULL),
  ( 2, 'CXP', 'Devolucion Gasto',     'GAS',  'Devolucion Gasto',     -1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Entrada Compra',       'COMS', 'Entrada Compra',        1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Entrada Insumo',       'COMS', 'Entrada Insumo',        1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Entrada Maquila',      'COMS', 'Entrada Maquila',       1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Entrada Maquila Fund', 'COMS', 'Entrada Maquila Fund',  1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Entrada Servicio',     'COMS', 'Entrada Servicio',      1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Gasto Prorrateado',    'GAS',  'Gasto',                 1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Gastos Fletes',        'GAS',  'Gastos Fletes',         1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Gastos Generales',     'GAS',  'Gastos Generales',      1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Pago',                 'CXP',  'Pago',                 -1, 0, 0, NULL,  NULL)

SELECT
  ID,
  Tipo,
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
  CUP_ConciliacionCont_Tipo_OrigenContable
ORDER BY
  ID