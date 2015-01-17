use Zeus
GO

DROP TRIGGER trigger_after_insert_factura
GO

CREATE TRIGGER trigger_after_insert_factura
ON RTL_TRANSACCION
AFTER INSERT
AS
BEGIN
	DECLARE @factura_id bigint,
		@fecha_real datetime,
		@tipo_cui varchar(5),
		@razon_social varchar(20),
		@nro_cui varchar(20),
		@basico numeric(18, 4),
		@monto_total numeric(18, 4),
		@emisor_numeracion varchar(200),
		@numero_comprobante varchar(200),
		@impuestos_total varchar(200),
		@factura_primary_key varchar(200);

	SELECT TOP 1 @fecha_real = ins.fecha_real, 
		@tipo_cui = ins.tipo_cui, 
		@razon_social = ins.razon_social, 
		@nro_cui = ins.nro_cui, 
		@basico = ins.basico, 
		@monto_total = ins.monto_total,
		@emisor_numeracion = ins.emisor_numeracion,
		@numero_comprobante = ins.nro_comprobante,
		@impuestos_total = ins.impuestos_total,
		@factura_primary_key = (CAST(ins.nodo as varchar(200)) + '-' + CAST(ins.pos as varchar(200)) + '-' + CAST(ins.transaccion as varchar(200)))
	FROM INSERTED as ins
	
	EXECUTE [bd_safdi3].[dbo].sp_crear_factura
		@fecha_real, 
		@tipo_cui, 
		@razon_social, 
		@nro_cui, 
		@basico, 
		@monto_total,
		@emisor_numeracion,
		@numero_comprobante,
		@impuestos_total,
		@factura_primary_key,
		@id = @factura_id OUTPUT;
END
GO

DROP TRIGGER trigger_after_insert_detalle
GO

CREATE TRIGGER trigger_after_insert_detalle
ON RTL_TRANS_DETALLE
AFTER INSERT
AS
BEGIN
	DECLARE @descripcion_articulo VARCHAR(50),
		@cantidad NUMERIC(18,6),
		@precio_unit_original NUMERIC(18,4),
		@basico_original NUMERIC(18,8),	
		@monto NUMERIC(16,4),
		@monto_calculado NUMERIC(18,8),
		@factura_primary_key VARCHAR(200),
		@orden varchar(10),
		@factura_detalle_id BIGINT;
	
	SELECT TOP 1 @descripcion_articulo = ins.descr_articulo, 
		@cantidad = ins.cantidad, 
		@precio_unit_original = ins.precio_unit_original, 
		@basico_original = ins.basico_original,
		@monto = ins.monto,
		@orden = ins.orden,
		@factura_primary_key = (CAST(ins.nodo AS VARCHAR(200)) + '-' + CAST(ins.pos AS VARCHAR(200)) + '-' + CAST(ins.transaccion AS VARCHAR(200)))
	FROM INSERTED AS ins
	
	--El monto calculado representa el monto sin impuestos, este valor no se registra por detalle en el sistema zeus solamente aparece en la TRANSACCION
	SET @monto_calculado = @cantidad * @basico_original
	
	EXECUTE [bd_safdi3].[dbo].sp_crear_factura_detalle
		@descripcion_articulo, 
		@cantidad, 
		@precio_unit_original, 
		--@monto, --Al ser el precio unitario sin impuesto no se usa el monto de zeus sino el monto calculado que no tiene el impuesto
		@monto_calculado,
		@factura_primary_key,
		@orden,
		@factura_detalle_id = @factura_detalle_id OUTPUT;
END
GO

DROP TRIGGER trigger_after_insert_impuesto
GO

CREATE TRIGGER trigger_after_insert_impuesto
ON RTL_TRANS_IMPUESTOS
AFTER INSERT
AS
BEGIN
	DECLARE @tasa NUMERIC(16,4),
		@base_imponible NUMERIC(18,8),
		@monto_impuesto NUMERIC(16,4),
		@valor NUMERIC(18,8),
		@base_imponible_calculada NUMERIC(18,8),
		@factura_detalle_id bigint,
		@factura_primary_key VARCHAR(200),
		@cantidad NUMERIC(18,6),
		@factura_impuesto_id BIGINT;
	
	SELECT TOP 1 @tasa = ins.tasa, 
		@base_imponible = ins.base_imponible, 
		@monto_impuesto = ins.monto_impuesto, 
		@valor = ins.valor,
		@cantidad = ins.cantidad,
		@factura_primary_key = (CAST(ins.nodo AS VARCHAR(200)) + '-' + CAST(ins.pos AS VARCHAR(200)) + '-' + CAST(ins.transaccion AS VARCHAR(200)) + '-' + CAST(ins.orden AS VARCHAR(200)))
	FROM INSERTED AS ins
	
	SET @base_imponible_calculada = @cantidad * @base_imponible

	EXECUTE [bd_safdi3].[dbo].sp_crear_factura_impuesto
		@base_imponible_calculada, 
		@tasa, 
		@monto_impuesto, 
		--@valor,
		--@base_imponible_calculada,
		@factura_primary_key;
END
GO