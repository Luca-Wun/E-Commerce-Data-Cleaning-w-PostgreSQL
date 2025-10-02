---------------- FEHLERANALYSE CUSTOMER_DATA ----------------------------------------------------------


-------- KONTROLLE USER_ID ------------------------------------------------------

-- keine Duplikate
SELECT user_id
FROM customer_data cd 
GROUP BY cd.user_id 
HAVING COUNT(*) > 1;


-------- INKONSISTENTE NAMEN -----------------------------------------------------

-- Komma statt Leerzeichen, Namen in Groß-/Kleinbuchstaben
SELECT name
FROM customer_data
LIMIT 100;


-- 489 mal groß-, 506 mal kleingeschrieben
SELECT COUNT(*) 
FROM customer_data
WHERE name = UPPER(name); --/LOWER

-- 505 Namen mit Komma, 507 mit doppeltem Leerzeichen
SELECT COUNT(*) 
FROM customer_data
WHERE name LIKE '%,%'; --/'  '

-- Namen im falschen Format
SELECT name
FROM customer_data
WHERE name !~ '^[A-Z][a-z]+(?:\s[A-Z][a-z]+)*$';



-------- EINGABEFEHLER ADRESSE -----------------------------------------------------

-- Großschreibung inkonsistent, Doppelte Kommata, Komma innerhalb des Stadt- oder Straßennamens
SELECT address
FROM customer_data
LIMIT 100;

-- 525 mal großgeschrieben, 517 mal kleingeschrieben
SELECT COUNT(*) 
FROM customer_data
WHERE address = UPPER(address); --/LOWER

--518 mal mehr als ein Komma
SELECT COUNT(*)
FROM customer_data
WHERE (LENGTH(address) - LENGTH(REPLACE(address, ',', ''))) > 1; 


-------- EINGABEFEHLER MAIL -----------------------------------------------------

-- Adressen großgeschrieben
SELECT email
FROM customer_data
LIMIT 100;

-- 325 mal vollständig großgeschrieben
SELECT COUNT(*) 
FROM customer_data
WHERE email = UPPER(email);

-- Suche nach klassischen Fehlern: 56 mal gmial statt gmail, 342 mal kein @ zeichen, 3 mal yaho.com
SELECT email
FROM customer_data
WHERE email LIKE '% %'; --/LIKE gmial/.con/yaho/.comm/hotmial/' '


-------- EINGABEFEHLER TELEFONNUMMER ------------------------------------------------

-- sehr inkonsisten, Bindestriche, Klammern und Punkte, +mit Ländervorwahl, Buchstaben in der Nummer
SELECT phone_number
FROM customer_data
LIMIT 100;

-- in den meisten (18.242) Nummern sind nicht nur Zahlen enthalten. 
-- In 13.968 Bindestriche, 3951 Klammern, 3170 Pluszeichen, 4020 Punkte, 11656 Buchstaben
SELECT COUNT(*)
FROM customer_data
WHERE phone_number !~ '^\+?[0-9]+$'; --/-/+/(/./~ '[A-Za-z]'

-- 315 sehr kurze Telefonnummern - unplausibel
SELECT phone_number
FROM customer_data
WHERE CHAR_LENGTH(phone_number) < 8;


-------- KONTROLLE GEBURTSDATUM ------------------------------------------------------

-- keine falsche Formatierung
SELECT COUNT(*)
FROM customer_data
WHERE birth_date !~ '^\d{4}-\d{2}-\d{2}$';

-- Umwandlung zu Datum, um besser weiter zu untersuchen
ALTER TABLE customer_data
ALTER COLUMN birth_date TYPE date
USING to_date(birth_date, 'YYYY-MM-DD');

-- keine Einträge in der Zukunft
SELECT COUNT(*)
FROM customer_data
WHERE birth_date > CURRENT_DATE;

-- 394 Einträge mit 01.01.1900 - unplausibel und vermutlich ein Fehler
SELECT birth_date
FROM customer_data
ORDER BY birth_date ASC;


-------- INKONSISTENTE DATEN REGISTRIERUNGSDATUM -----------------------------------------

-- inkonsistentes Format
SELECT registration_date 
FROM customer_data
LIMIT 100;

-- 13.251 falsch formatierte Daten
SELECT registration_date
FROM customer_data
WHERE registration_date !~ '^\d{4}-\d{2}-\d{2}$';

-- 6600 mit Bindestrich, 6653 mit Punkt, 6598 mit Schrägstrich
SELECT COUNT(*)
FROM customer_data
WHERE registration_date LIKE '%/%'; --/-//

-- alle mit Bindestrich im korrekten Format (YYYY-MM-DD), bei Punkten alle in DD.MM.YYYY, bei Schrägstrich in MM/DD/YYYY
SELECT COUNT(*)  
FROM customer_data
WHERE registration_date ~ '^\d{2}/\d{2}/\d{4}$'; --/ '^\d{2}\.\d{2}\.\d{4}$' / '^\d{4}-\d{2}-\d{2}$'

-- Bestätigung der Datenformate bezüglich Platzierung von Tag und Monat
SELECT COUNT(*)
FROM customer_data
WHERE SUBSTRING(registration_date FROM 1 FOR 2)::int > 12
  AND registration_date ~ '^\d{2}/\d{2}/\d{4}$'; --/ '^\d{2}\.\d{2}\.\d{4}$' / '^\d{4}-\d{2}-\d{2}$'
    

-------- INKONSISTENTE BENENNUNG BONUS_MEMBER -----------------------------------------

-- Ja-Werte mit Yes, Y oder True, Nein-Werte mit No, N oder FALSE
SELECT bonus_member, COUNT(*)
FROM customer_data
GROUP BY bonus_member;