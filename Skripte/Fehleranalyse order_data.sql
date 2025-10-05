---------------- FEHLERANALYSE ORDER_DATA ----------------------------------------------------------


-------- KONTROLLE USER_ID ------------------------------------------------------

-- keine auffälligen Werte
SELECT user_id
FROM order_data
WHERE user_id = ''; --ALTERNATIVE: /NULL/' '



-------- DUPLIKATE IN ORDER-ID ---------------------------------------------------

-- es gibt 145 Duplikate von order_id
SELECT order_id, COUNT(*) AS count
FROM order_data
GROUP BY order_id
HAVING COUNT(*) > 1;


-- in 37 Fällen sind es exakte Duplikate 
WITH row_num_cte AS(
	SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY order_id,
				 user_id, 
				 product_id,
				 purchase_ts
	) row_num
	FROM order_data
)

SELECT *
FROM row_num_cte 
WHERE row_num > 1;


-- nach Stichprobenkontrolle: Nur die user_ids unterscheidet sich
WITH order_double AS(
	SELECT order_id, COUNT(*)
	FROM order_data
	GROUP BY order_id
	HAVING COUNT(*)>1
)

SELECT row_number() OVER (PARTITION BY order_id) AS row_num, *
FROM order_data
WHERE order_id IN (SELECT order_id FROM order_double);


-- keine leeren, NULL oder Leerzeichen
SELECT order_id
FROM order_data
WHERE order_id = ''; --ALTERNATIVE: /NULL/' '



-------- FEHLER IN PURCHASE TIMESTAMP --------------------------------------

-- erster überblick: es gibt falsch formatierte Daten, mit '-' und Uhrzeit
SELECT purchase_ts, COUNT(*)
FROM order_data
GROUP BY purchase_ts
LIMIT 1000;

-- 10 Reihen sind betroffen
SELECT purchase_ts
FROM order_data 
WHERE purchase_ts LIKE '%-%';

-- Ein Wert hat außerdem zwei Leerzeichen
SELECT * 
FROM order_data
WHERE purchase_ts = '  '; --ALTERNATIVE: /NULL/''


-------- FEHLER IN SHIP TIMESTAMP ------------------------------------------

-- keine Null-Werte, keine Werte mit Bindestrichen
SELECT * 
FROM order_data
WHERE ship_ts LIKE '%-%'; --ALTERNATIVE: /NULL/''/'  '

-- Versanddatum ist häufig vor dem Bestelldatum
SELECT purchase_ts, ship_ts
FROM order_data
WHERE ship_ts < purchase_ts;

-- in 2000 Fällen (Kontrolle in korrekt formatierten Daten)
SELECT COUNT(*)
FROM order_data_clean
WHERE ship_ts_clean < purchase_ts_clean;


-------- INKONSISTENTE PRODUKTNAMEN ----------------------------------------

--Ergebnis: Name des Gaming monitors in 61 Reihen falsch geschrieben
SELECT product_name, COUNT(*)
FROM order_data
GROUP BY product_name
ORDER BY product_name ASC;


-------- KONTROLLE DER PRODUKT-IDs ------------------------------------------ 

-- keine Auffälligkeiten
SELECT product_id 
FROM order_data
GROUP BY product_id;

-- allen Produkten haben mehrere assoziierte Product IDs. Nicht unbedingt problematisch, könnte man Rücksprache halten
SELECT product_name, product_id, COUNT(*)
FROM order_data
GROUP BY product_name, product_id
ORDER BY product_name ASC;

-- jede Produkt ID ist nur mit einem Produktnamen assoziiert
SELECT product_id, product_name, COUNT(*)
FROM order_data od 
GROUP BY product_id, product_name 
ORDER BY product_id ASC;


-------- FEHLENDE UND SINNLOSE WERTE IN USD_PRICE --------------------------
-- 5 fehlende Werte, 29 Werte mit 0. Nicht als Zahl formatiert, deswegen nicht korrekt ASC
SELECT usd_price, COUNT(*)
FROM order_data
GROUP BY order_data.usd_price 
ORDER BY usd_price ASC;


-------- FEHLENDE WERTE IM MARKETING CHANNEL -----------------------------------

-- 47 mal unknown, 83 fehlende Werte ('')
SELECT marketing_channel, COUNT(*)
FROM order_data
GROUP BY marketing_channel;


-------- KONTROLLE DER PURCHASE PLATTFORM --------------------------------------

-- keine Auffälligkeiten
SELECT purchase_platform
FROM order_data od 
GROUP BY purchase_platform;


-------- FEHLENDE WERTE IN DER ACCOUNT_CREATION ---------------------------------
-- 743 mal unknown, 83 mal fehlend ('')
SELECT account_creation_method, COUNT(*)
FROM order_data
GROUP BY account_creation_method;


-------- FEHLENDE WERTE IM COUNTRY CODE -----------------------------------------
-- 37 fehlende Werte ('')
SELECT country_code, COUNT(*)
FROM order_data
GROUP BY country_code
ORDER BY country_code;



