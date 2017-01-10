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
   /* IVA Por Acreeditar */
  ( 2, 'CXP', 'Anticipo',             'CXP',  'Anticipo',             -1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Aplicacion',           'CXP',  'Aplicacion',            1, 1, 0, NULL,  NULL),
  ( 2, 'CXP', 'Cargo Proveedor' ,     'CXP',  'Cargo Proveedor',       1, 0, 0, NULL,  NULL),
  ( 2, 'CXP', 'Correccion Rebate',    'CXP',  'Correccion Rebate',     1, 0, 0, NULL,  NULL),
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
  ( 2, 'CXP', 'Pago',                 'CXP',  'Pago',                 -1, 0, 0, NULL,  NULL),
   /* Saldo Clientes  */
  ( 3, 'CXC', 'Ajuste',               'CXC',  'Ajuste',                1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Ajuste Redondeo',      'CXC',  'Ajuste Redondeo',       1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Aplicacion',           'CXC',  'Aplicacion',            1, 1, 0, NULL,  NULL),
  ( 3, 'CXC', 'Cobro' ,               'CXC',  'Cobro',                -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Cobro Anticipo',       'CXC',  'Cobro Anticipo',       -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Conversion Cargo',     'CXC',  'Conversion Cargo',     -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Conversion Credito',   'CXC',  'Conversion Credito',    1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Cheque Devuelto',      'CXC',  'Cheque Devuelto',       1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Devolucion',           'CXC',  'Devolucion',           -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Devol Anticipo CFD',   'CXC',  'Devol Anticipo CFD',    1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Devol Anticipo',       'CXC',  'Devol Anticipo',        1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Fact Ant Pitex CFD',   'CXC',  'Fact Ant Pitex CFD',   -1, 0, 0, NULL,  NULL),
--( 3, 'CXC', 'Factura Anticipo CFD', 'CXC',  'Factura Anticipo CFD', -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Factura Export CFD',   'VTAS', 'Factura Export CFD',    1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Factura Vta CFD',      'VTAS', 'Factura Vta CFD',       1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Cargo CFD',       'CXC',  'Nota Cargo CFD',        1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Cargo Serv CFD',  'CXC',  'Nota Cargo Serv CFD',   1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito',         'CXC',  'Nota Credito',         -1, 0, 1, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CFD',     'CXC',  'Nota Credito CFD',     -1, 0, 1, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CFD',     'VTAS', 'Bonif Act Fijo CFD',   -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CFD',     'VTAS', 'Bonif Pitex CFD',      -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CFD',     'VTAS', 'Bonif Vta Export CFD', -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CFD',     'VTAS', 'Bonificacion Vta CFD', -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CFD',     'VTAS', 'Devolucion Expor CFD', -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CFD',     'VTAS', 'Devolucion Pitex CFD', -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CFD',     'VTAS', 'Devolucion Vta CFD',   -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Nota Credito CS CFD',  'CXC',  'Nota Credito CS CFD',  -1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Saldo Fact Torr',      'CXC',  'Saldo Fact Torr',      -1, 0, 1, NULL,  NULL),
  ( 3, 'CXC', 'Saldos Cte',           'CXC',  'Saldos Cte',           -1, 0, 1, NULL,  NULL),
  ( 3, 'CXC', 'Reevaluacion',         'CXC',  'Reevaluacion',          1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Reevaluacion Credito', 'CXC',  'Reevaluacion Credito',  1, 0, 0, NULL,  NULL),
  ( 3, 'CXC', 'Vta Activo Fijo CFD',  'VTAS',  'Vta Activo Fijo CFD',  1, 0, 0, NULL,  NULL),
  /* IVA Trasladado */
  ( 4, 'CXC', 'Ajuste',               'CXC',  'Ajuste',                1, 1, 0, NULL,  NULL),
  ( 4, 'CXC', 'Aplicacion Saldo',     'CXC',  'Aplicacion Saldo',     -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Cobro' ,               'CXC',  'Cobro',                -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Cobro Anticipo',       'CXC',  'Cobro Anticipo',       -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Conversion Cargo',     'CXC',  'Conversion Cargo',     -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Conversion Credito',   'CXC',  'Conversion Credito',    1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Cheque Devuelto',      'CXC',  'Cheque Devuelto',       1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Deposito',             'DIN',  'Deposito',             -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Devolucion',           'CXC',  'Devolucion',           -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Devol Anticipo CFD',   'CXC',  'Devol Anticipo CFD',    1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Devol Anticipo',       'CXC',  'Devol Anticipo',        1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Fact Ant Pitex CFD',   'CXC',  'Fact Ant Pitex CFD',   -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Factura Export CFD',   'VTAS', 'Factura Export CFD',    1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Factura Vta CFD',      'VTAS', 'Factura Vta CFD',       1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Cargo CFD',       'CXC',  'Nota Cargo CFD',        1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Cargo Serv CFD',  'CXC',  'Nota Cargo Serv CFD',   1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito',         'CXC',  'Nota Credito',         -1, 0, 1, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CFD',     'CXC',  'Nota Credito CFD',     -1, 0, 1, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CFD',     'VTAS', 'Bonif Act Fijo CFD',   -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CFD',     'VTAS', 'Bonif Pitex CFD',      -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CFD',     'VTAS', 'Bonif Vta Export CFD', -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CFD',     'VTAS', 'Bonificacion Vta CFD', -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CFD',     'VTAS', 'Devolucion Expor CFD', -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CFD',     'VTAS', 'Devolucion Pitex CFD', -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CFD',     'VTAS', 'Devolucion Vta CFD',   -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Nota Credito CS CFD',  'CXC',  'Nota Credito CS CFD',  -1, 0, 0, NULL,  NULL),
  ( 4, 'CXC', 'Saldo Fact Torr',      'CXC',  'Saldo Fact Torr',      -1, 0, 1, NULL,  NULL),
  ( 4, 'CXC', 'Saldos Cte',           'CXC',  'Saldos Cte',           -1, 0, 1, NULL,  NULL),
  ( 4, 'CXC', 'Vta Activo Fijo CFD',  'VTAS',  'Vta Activo Fijo CFD',   1, 0, 0, NULL,  NULL)


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