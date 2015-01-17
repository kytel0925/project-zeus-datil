--Agregando campos para rastreo de keys de transaccion y transaccion detalle
use bd_safdi3
GO

ALTER TABLE DocElectronicoFactura.factura 
ADD transaccion_primary_key varchar(200) NULL

CREATE INDEX DocElectronicoFactura_factura_transaccion_pimary_key
ON DocElectronicoFactura.factura(transaccion_primary_key)
GO

ALTER TABLE DocElectronicoFactura.detalle 
ADD transaccion_detalle_primary_key varchar(200) NULL

CREATE INDEX DocElectronicoFactura_detalle_transaccion_detalle_pimary_key
ON DocElectronicoFactura.detalle (transaccion_detalle_primary_key)
GO
