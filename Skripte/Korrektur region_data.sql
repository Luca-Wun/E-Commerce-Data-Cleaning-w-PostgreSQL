-------- ANLEGEN VON KORRIGIERTER REGION_DATA TABELLE -----------------------------------

CREATE TABLE region_data_clean AS

SELECT country_code,

-- UNREGELMÄßIGKEITEN IN REGION KORRIGIERT --------------------------
CASE
	WHEN region = 'X.x' THEN 'APAC'
	WHEN region = 'North America' THEN 'NA'
	WHEN region = '' THEN 'EMEA'
	ELSE region
END AS region_clean

FROM region_data;


-- HINZUFÜGEN DER MISSMATCHED COUNTRY CODES ------------------------
INSERT INTO region_data_clean (
	country_code, 
	region_clean
)
VALUES
('AP', 'APAC'),
('EU', 'EMEA');



-------- SETZEN VON PRIMARY KEY ---------------------------------------------------------
ALTER TABLE region_data_clean
ADD PRIMARY KEY (country_code);



-------- SETZEN VON FOREIGN KEY ZUR VERBINDUNG ------------------------------------------
ALTER TABLE order_data_clean
ADD CONSTRAINT fk_country
FOREIGN KEY (country_code_clean)
REFERENCES region_data_clean(country_code);