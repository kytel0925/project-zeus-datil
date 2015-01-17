--Base de datos donde se almacenaran los procedimientos almacenados
USE bd_safdi3
GO

DROP PROCEDURE sp_crear_factura
GO

CREATE PROCEDURE sp_crear_factura
	@factura_fecha_emision datetime, --RTL_TRANSACCION.fecha_real
	@factura_tipo_cui varchar(200), --RTL_TRANSACCION.tipo_cui
	@factura_razon_social_comprador varchar(200), --RTL_TRANSACCION.razon_social
	@factura_indentificador_comprador varchar(200), --RTL_TRANSACCION.nro_cui
	@factura_total_sin_impuestos varchar(200), --RTL_TRANSACCION.basico
	@factura_importe_total varchar(200), --RTL_TRANSACCION.monto_total
	@emisor_numeracion varchar(200), --RTL_TRANSACCION.emisor_numeracion
	@numero_comprobante varchar(200), --RTL_TRANSACCION.nro_comprobante
    @impuestos_total varchar(200), --RTL_TRANSACCION.impuestos_total
	@factura_primary_key varchar(200), --RTL_TRANSACCION CONCAT(nodo, pos, transaccion)
	
	@id BIGINT OUTPUT
AS
BEGIN
	DECLARE @factura_id_id varchar(200),
		@factura_version varchar(200),
		@factura_estado varchar(200),
		@factura_check_id bigint
	
	PRINT @factura_primary_key
	SET @factura_check_id = (
		select id_factura FROM DocElectronicoFactura.factura WHERE
		transaccion_primary_key = @factura_primary_key
	);
	--Verificamos la existencia del id de factura
	IF @factura_primary_key <> '' AND @factura_check_id IS NOT NULL
	BEGIN
		SET @id = @factura_check_id
		
		RETURN
	END;
	
	SET @id = (SELECT MAX(id_factura) + 1 from DocElectronicoFactura.factura)
	IF @id IS NULL
	BEGIN
		SET @id = 1
	END	
	SET @factura_id_id = 'comprobante'
	SET @factura_version = '1.0.0'
	SET @factura_estado = 'POR AUTORIZAR'

	INSERT INTO DocElectronicoFactura.factura 
	VALUES(@id, @factura_id_id, @factura_version, @factura_estado, NULL, NULL, NULL, @factura_primary_key)
	
	--Insertamos la informacion de infoFactura
	DECLARE @factura_direccion_establecimiento varchar(200),
		@factura_contribuyete_especial varchar(200),
		@factura_obligado_contabilidad varchar(200),
		@factura_tipo_indentificador_comprador varchar(200),
		@factura_guia_remision varchar(200),
		@factura_total_descuentos varchar(200),
		@factura_propina varchar(200),
		@factura_moneda varchar(200)
		
	SET @factura_direccion_establecimiento = 'AV.JUAN TANCA MARENGO KM 4.5 COOP.MADRIGAL';
	SET @factura_contribuyete_especial = '5505'
	SET @factura_obligado_contabilidad = 'SI'
	SET @factura_tipo_indentificador_comprador = 
		CASE @factura_tipo_cui
			WHEN 'CR' THEN '05' --Cedula
			WHEN 'CRF' THEN '04' --Ruc
			ELSE '07' --Consumidor final
		END;
	SET @factura_guia_remision = ''
	SET @factura_total_descuentos = '0'
	SET @factura_propina = '0'
	SET @factura_moneda = 'DOLAR'
	
	INSERT INTO DocElectronicoFactura.infoFactura VAlUES(
		@id, 
		@factura_fecha_emision, 
		@factura_direccion_establecimiento,
		@factura_contribuyete_especial,
		@factura_obligado_contabilidad,
		@factura_tipo_indentificador_comprador,
		@factura_guia_remision,
		@factura_razon_social_comprador,
		@factura_indentificador_comprador,
		@factura_total_sin_impuestos,
		@factura_total_descuentos,
		@factura_propina,
		@factura_importe_total,
		@factura_moneda
	);
	
	--Insertamos la infoTributaria
	DECLARE @infoTributaria_ambiente int,
	@tipoEmision int,
	@razonSocial varchar(300),
	@nombreComercial varchar(300),
	@ruc varchar(13),
	@claveAcceso varchar(49),
	@codDocumento varchar(2),
	@establecimiento varchar(3),
	@puestoEmision varchar(3),
	@secuencial varchar(9),
	@dirMatriz varchar(300)
	
	SET @establecimiento = SUBSTRING(@emisor_numeracion, 1, 3)
	SET @puestoEmision = SUBSTRING(@emisor_numeracion, 4, 3)
	SET @infoTributaria_ambiente = 2
	SET @tipoEmision = 1
	SET @razonSocial = '' --Razon social del emisor
	SET @nombreComercial = '' --Nombre comercial del emisor
	SET @ruc = '' --Ruc del emisor
	SET @claveAcceso = ''
	SET @codDocumento = '01'
	SET @secuencial = @numero_comprobante
	SET @dirMatriz = ''
	
	INSERT INTO DocElectronicoFactura.infoTributaria VALUES(
		@id,
		@infoTributaria_ambiente,
		@tipoEmision,
		@razonSocial,
		@nombreComercial,
		@ruc,
		@claveAcceso,
		@codDocumento,
		@establecimiento,
		@puestoEmision,
		@secuencial,
		@dirMatriz
	)
	
	--Insertamos el totalImpuesto
	DECLARE	@codigo int,
	@codigoPorcentaje int,
	@baseImponible varchar(200),
	@tarifa numeric(10,6),
	@valor varchar(200)
	
	SET @codigo = 1
	SET @codigoPorcentaje = 1
	SET @baseImponible = @factura_total_sin_impuestos
	SET @tarifa = 12.0
	SET @valor = @impuestos_total
	
	INSERT INTO DocElectronicoFactura.totalImpuesto VALUES (
		@id,
		@codigo,
		@codigoPorcentaje,
		@baseImponible,
		@tarifa,
		@valor
	)
	
	RETURN
END
GO

DROP PROCEDURE sp_crear_factura_detalle
GO

CREATE PROCEDURE sp_crear_factura_detalle
	@factura_detalle_descripcion varchar(200),
	@factura_detalle_cantidad varchar(200),
	@factura_detalle_precio_unitario varchar(200),
	@factura_detalle_precio_total_sin_impuesto varchar(200),
	@factura_primary_key varchar(200),
	@factura_detalle_orden varchar(200),
	
	@factura_detalle_id BIGINT OUTPUT
AS
BEGIN
	--Localizamos el id de la factura mediente el primary key
	DECLARE @factura_id bigint
	
	SET @factura_id = (
		select id_factura FROM DocElectronicoFactura.factura WHERE
		transaccion_primary_key = @factura_primary_key AND transaccion_primary_key IS NOT NULL
	);
	
	IF @factura_id IS NULL
	BEGIN
		PRINT @factura_primary_key + ' no existe'
		
		RETURN
	END;
	
	--Creacion de registro del detalle
	DECLARE @factura_detalle_codigo_principal varchar(200),
	@factura_detalle_codigo_auxiliar varchar(200),
	@factura_detalle_descuento varchar(200)
	
	SET @factura_detalle_id = (
		SELECT MAX(id_detalle) + 1 from DocElectronicoFactura.detalle
	);
	IF @factura_detalle_id IS NULL
	BEGIN
		SET @factura_detalle_id = 1
	END	
	
	SET @factura_detalle_codigo_principal = '000000'
	SET @factura_detalle_codigo_auxiliar = '000000'
	SET @factura_detalle_descuento = '0'
	SET @factura_detalle_orden = @factura_primary_key + '-' + @factura_detalle_orden 
	
	INSERT INTO DocElectronicoFactura.detalle VALUES(
		@factura_detalle_id, 
		@factura_id,
		@factura_detalle_codigo_principal,
		@factura_detalle_codigo_auxiliar,
		@factura_detalle_descripcion,
		@factura_detalle_cantidad,
		@factura_detalle_precio_unitario,
		@factura_detalle_descuento,
		@factura_detalle_precio_total_sin_impuesto,
		@factura_detalle_orden
	);
	RETURN
END
GO

DROP PROCEDURE sp_crear_factura_impuesto
GO

CREATE PROCEDURE sp_crear_factura_impuesto
	 @base_imposible_calculada varchar(200),
	 @tarifa varchar(200),
	 @valor varchar(200),
	 --@impuesto_valor varchar(200),
	 --@base_imposible_calculada numeric(18,8),
	 @transaccion_detalle_primary_key varchar(200)
	 
AS
BEGIN
	DECLARE @factura_detalle_id bigint
	
	SET @factura_detalle_id = (
		select id_detalle 
		FROM DocElectronicoFactura.detalle
		WHERE transaccion_detalle_primary_key = @transaccion_detalle_primary_key
	);
	
	IF @factura_detalle_id IS NULL
	BEGIN
		PRINT @transaccion_detalle_primary_key + ' no existe detalle'
		
		RETURN
	END;

	DECLARE @impuesto_codigo varchar(200),
		@codigo_porcentaje int
		
	SET @impuesto_codigo = '2'
	SET @codigo_porcentaje = 2
	
	INSERT INTO DocElectronicoFactura.impuesto VALUES(
		@factura_detalle_id,
		@impuesto_codigo,
		@codigo_porcentaje,
		@base_imposible_calculada,
		@tarifa,
		@valor
	);
	RETURN
END
GO