---------------- FEHLERANALYSE REGION_DATA ----------------------------------------------------------

-------- KONTROLLE DER COUNTRY CODES --------------------------------------

-- keine auffälligen Werte
SELECT country_code, COUNT(*)
FROM region_data
GROUP BY country_code;

-- keine doppelten Werte
SELECT country_code, COUNT(*)
FROM region_data
GROUP BY country_code;
HAVING COUNT(*) >1;


-------- FEHLENDE UND SINNLOSE WERTE IN REGION --------------------------

-- sinnloser Wert X.x (2) und fehlende Werte (2). Dopplung bei NA und North America? (5)
SELECT region, COUNT(*)
FROM region_data
GROUP BY region;

-- Kontrolle der zugeordneten Länder: NA und North America steht für das gleiche
SELECT region, country_code 
FROM region_data
WHERE region = 'North America'; --/'NA'

-- Kontrolle der zugeordneten Länder: Region X.x gehört zu APAC
SELECT country_code, region 
FROM region_data
WHERE region = 'X.x';

-- Kontrolle der zugeordneten Länder: leere Werte gehören zu EMEA
SELECT country_code, region
FROM region_data
WHERE region = '';


-------- MISMATCH BEI COUNTRY CODES ZWISCHEN DEN TABELLEN --------------------

-- EU & AP aus der Order Tabelle ist nicht in der Region Tabelle und auch keine validen Ländercodes
SELECT country_code, COUNT(*)
FROM order_data
WHERE country_code NOT IN(
	SELECT country_code FROM region_data
)
GROUP BY country_code;