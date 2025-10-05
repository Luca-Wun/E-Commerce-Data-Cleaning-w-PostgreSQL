-------- ANLEGEN VON KORRIGIERTER CUSTOMER_DATA TABELLE --------------------------------------------------

CREATE TABLE customer_data_clean AS


SELECT user_id,

-- KORREKTUR INKONSISTENTER NAMEN ---------------------------------------
CASE
	WHEN name LIKE '%,%' THEN INITCAP(REPLACE(name, ',', ' '))
	WHEN name LIKE '%  %' THEN INITCAP(REPLACE(name, '  ', ' '))
ELSE INITCAP(name) 
END AS name_clean,


-- KORREKTUR EINGABEFEHLER ADRESSE, AUFTEILUNG STRAßE UND STADT ---------
REPLACE(
		INITCAP(
				REGEXP_REPLACE(
               				    REPLACE(address, ',', ' '),   
               					'^(.+[0-9]+[A-Za-z]?).*$',
               					'\1'
        		)
		), '  ', ' '
) AS address_street_clean,


INITCAP(
		REGEXP_REPLACE(
               		    REPLACE(address, ',', ''),   
               			 '^.*?[0-9]+[A-Za-z]?\s*(.*)$',  
               			'\1'
        )
) AS address_city_clean,


-- KORREKTUR EINGABEFEHLER MAIL -----------------------------------------
CASE
	WHEN email LIKE '%gmial%' THEN LOWER(REPLACE(email, 'gmial', 'gmail'))
	WHEN email LIKE '%yaho.' THEN LOWER(REPLACE(email, 'yaho.', 'yahoo.'))
	WHEN email LIKE '%gmail.com' AND email NOT LIKE '%@%' THEN REPLACE(email, 'gmail', '@gmail')
	WHEN email LIKE '%yahoo.com' AND email NOT LIKE '%@%' THEN REPLACE(email, 'yahoo', '@yahoo')
	WHEN email LIKE '%hotmail.com' AND email NOT LIKE '%@%' THEN REPLACE(email, 'hotmail', '@hotmail')
	WHEN email LIKE '%outlook.com' AND email NOT LIKE '%@%' THEN REPLACE(email, 'outlook', '@outlook')
ELSE LOWER(email)
END AS email_clean,


-- KORREKTUR EINGABEFEHLER TELEFONNUMMER --------------------------------
CASE 
	WHEN LENGTH(
				REGEXP_REPLACE(
								REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g'), '^00', '+')
		) < 8 THEN NULL
ELSE REGEXP_REPLACE(
					REGEXP_REPLACE(phone_number, '[^0-9+]', '', 'g'), '^00', '+') 
END AS phone_number_clean,


-- AUSSCHLUSS UNPLAUSIBLE GEBURTSDATEN ----------------------------------
CASE 
	WHEN birth_date < CURRENT_DATE - INTERVAL '120 years'  THEN NULL
ELSE birth_date
END AS birth_date_clean,


-- STANDARDISIERUNG REGISTRIERUNGSDATUM ---------------------------------
CASE
	WHEN registration_date ~ '^\d{2}/\d{2}/\d{4}$' THEN to_date(registration_date, 'MM/DD/YYYY')
	WHEN registration_date ~ '^\d{2}\.\d{2}\.\d{4}$' THEN to_date(registration_date, 'DD.MM.YYYY')
	WHEN registration_date ~ '^\d{4}-\d{2}-\d{2}$' THEN to_date(registration_date, 'YYYY-MM-DD')
END AS registration_date_clean,


-- STANDARDISIERUNG BONUS_MEMBER KATEGORIEN------------------------------
CASE
	WHEN bonus_member In ('N', 'FALSE') THEN 'No'
	WHEN bonus_member IN ('Y', 'True') THEN 'Yes'
ELSE bonus_member
END AS bonus_member_clean


FROM customer_data cd;



-------- WEITERE KONTROLLEN ------------------------------------------------------------------------------

-- KONTROLLE MAILADRESSE -------------------------------------------------

-- 176 bleibende Fehler ohne @, aber kein bekannter Mailprovider. @-Position daher unbekannt.
SELECT COUNT(*)
FROM customer_data_clean
WHERE email_clean NOT LIKE '%@%';


-- KONTROLLE REGISTRATION_DATE -------------------------------------------

-- frühstes Datum plausibel
SELECT registration_date_clean
FROM customer_data_clean
ORDER BY registration_date_clean; 

-- keine Daten in der Zukunft
SELECT COUNT(*)
FROM customer_data_clean
WHERE registration_date_clean > CURRENT_DATE;

-- keine Registrierungsdaten vor dem Geburtsdatum
SELECT COUNT(*)
FROM customer_data_clean
WHERE registration_date_clean < birth_date_clean;


-- KORREKTUR TELEFONNUMMER ------------------------------------------------

-- bei 13162 Nummern fehlt die Ländervorwahl, daher weitere Tabelle mit Ländercodes und Vorwahlen integriert
SELECT COUNT(*)
FROM customer_data_clean
WHERE phone_number_clean NOT LIKE '%+%';


-- MODELLIERUNG DER DATEN -------------------------------------------------

-- Primary Keys erstellen
ALTER TABLE country_phone_codes
ADD CONSTRAINT pk_country_code PRIMARY KEY (country_code);

ALTER TABLE customer_data_clean
ADD CONSTRAINT pk_user_id PRIMARY KEY (user_id);

-- kein Missmatch von Country Codes
SELECT country_code_clean, COUNT(*)
FROM order_data_clean
WHERE country_code_clean NOT IN(
	SELECT country_code FROM country_phone_codes
)
GROUP BY country_code_clean;

-- Foreign Key erstellen zur Verbindung von order_data und country_phone_codes
ALTER TABLE order_data_clean
ADD CONSTRAINT fk_country_phone 
FOREIGN KEY (country_code_clean)
REFERENCES country_phone_codes(country_code);

-- Foreign Key erstellen zur Verbindung von order_data und customer_data_clean
ALTER TABLE order_data_clean
ADD CONSTRAINT fk_customer_data 
FOREIGN KEY (user_id)
REFERENCES customer_data_clean(user_id);


-- KORREKTUR DER TELEFONNUMMERN MIT LÄNDERVORWAHL -------------------------

UPDATE customer_data_clean cdc
SET phone_number_clean = CONCAT(cpc.phone_code, cdc.phone_number_clean)
FROM order_data_clean odc
JOIN country_phone_codes cpc 
	ON cpc.country_code = odc.country_code_clean
WHERE cdc.user_id = odc.user_id
	AND cdc.phone_number_clean NOT LIKE '%+%';