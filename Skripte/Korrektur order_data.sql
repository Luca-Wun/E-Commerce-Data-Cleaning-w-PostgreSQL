-------- ANLEGEN VON KORRIGIERTER ORDER_DATA TABELLE ---------------------------------------------------


CREATE TABLE order_data_clean AS

-- FINDEN DOPPELTER IDs --
WITH order_double AS(
SELECT order_id, COUNT(*)
FROM order_data
GROUP BY order_id
HAVING COUNT(*)>1
),

-- FINDEN DES JEWEILS ZWEITEN FALLS --
double_numbered AS(
SELECT ctid, order_id, row_number() OVER (PARTITION BY order_id) AS row_num
FROM order_data
WHERE order_id IN (SELECT order_id FROM order_double)
)


SELECT user_id, 

-- MARKIEREN DOPPELTER ORDER_IDS mit _DUP -------------------------------

CASE
	WHEN dn.row_num = 2 THEN CONCAT(od.order_id, '_DUP')
	ELSE od.order_id
END AS order_id_clean,


-- KORREKTUR DATUMSFORMAT, LEERER WERT, DATENTYP BEI PURCHASE_TS --------
	WHEN purchase_ts = '  ' THEN NULL
	WHEN purchase_ts LIKE '%-%' THEN to_date(split_part(purchase_ts, ' ', 1), 'MM-DD-YYYY')
	ELSE to_date(purchase_ts, 'DD.MM-YYYY')
END AS purchase_ts_clean,


-- KORREKTUR DATENTYP BEI SHIP_TS ---------------------------------------
to_date(ship_ts, 'DD.MM-YYYY') AS ship_ts_clean,


-- VEREINHEITLICHUNG PRODUKTNAMEN ---------------------------------------
CASE
	WHEN product_name LIKE '27inches%' THEN '27in 4K gaming monitor'
	ELSE product_name
END AS product_name_clean, 

product_id,


-- ENTFERNEN VON TRANSAKTIONEN MIT 0 ODER FEHLEND, DATENTYP NUMERISH ----
CASE
	WHEN usd_price  IN ('0', '', ' ') THEN NULL
	ELSE REPLACE(usd_price , ',', '.')::numeric
END AS usd_price_clean,


-- FEHLENDE WERTE IN MARKETING ZU UNKNOWN ------------------------------
CASE
	WHEN marketing_channel = ' ' THEN 'unknown'
	ELSE marketing_channel
END AS marketing_channel_clean,

purchase_platform,


-- FEHLENDE WERTE ACCOUNT_CREATION ZU UNKOWN ---------------------------
CASE
	WHEN account_creation_method = ' ' THEN 'unknown'
	ELSE account_creation_method
END AS account_creation_method_clean,


-- LEERE WERTE BEI COUNTRY CODE ZU NULL --------------------------------
CASE 
	WHEN country_code = '' THEN NULL
	ELSE country_code
END AS country_code_clean


FROM order_data od

LEFT JOIN double_numbered dn ON od.ctid = dn.ctid;


-------- SETZEN VON PRIMARY KEY --------------------------------------

ALTER TABLE order_data_clean
ADD PRIMARY KEY (order_id_clean);


--------- KALKULATION WEITERER SPALTEN --------------------------------

-- Berechnung der Anzahl Tage zwischen Bestellung und Versand
ALTER TABLE order_data_clean 
ADD COLUMN days_to_ship INT;

UPDATE order_data_clean
SET days_to_ship = ship_ts_clean - purchase_ts_clean;

-- ermöglicht leichtes filtern oder untersuchen der negativen Werte (Versand vor Bestellung)
SELECT purchase_ts_clean, ship_ts_clean, days_to_ship
FROM order_data_clean odc 
WHERE days_to_ship < 0;
