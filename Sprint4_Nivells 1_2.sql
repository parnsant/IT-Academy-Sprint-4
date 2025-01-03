/*Nivell 1

Descàrrega els arxius CSV, estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, 
almenys 4 taules de les quals puguis realitzar les següents consultes:*/

# Creo la nova base de dades
CREATE DATABASE IF NOT EXISTS Sprint_4;
USE Sprint_4;

# Creo la taula "credit_cards"
CREATE TABLE credit_cards (
	card_id VARCHAR(20) PRIMARY KEY,
	user_id VARCHAR(20) NOT NULL,
	iban VARCHAR(50) NOT NULL,
	pan VARCHAR(50) NOT NULL,
	pin VARCHAR(4) NOT NULL,
	cvv SMALLINT NOT NULL,
	track1 VARCHAR(255),
	track2 VARCHAR(255),
	expiring_date VARCHAR(20) NOT NULL
);

# Carrego les dades de "credit_cards" a la taula
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Comprovo que s'han carregat bé les dades

SELECT *
FROM credit_cards;


# Creo la taula "companies"
CREATE TABLE IF NOT EXISTS companies (
	company_id VARCHAR(15) PRIMARY KEY,
	company_name VARCHAR(255),
	phone VARCHAR(15),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(255)
);

# Carrego les dades a la taula "companies"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r'
IGNORE 1 ROWS ;

# Comprovo que s'han carregat bé:

SELECT *
FROM companies;


# Creo la taula "users"
CREATE TABLE IF NOT EXISTS users (
	user_id VARCHAR(20) PRIMARY KEY,
	name VARCHAR(150),
	surname VARCHAR(150),
	phone VARCHAR(150),
	email VARCHAR(150),
	birth_date VARCHAR(100),
	country VARCHAR(150),
	city VARCHAR(150),
	postal_code VARCHAR(100),
	address VARCHAR(255)
    );

# A la nova taula "users", hi passo la info de les taules "users_uk", "users_usa" i "users_ca".
# "users_ca"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_ca.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# "users_uk"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_uk.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# "users_usa"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users_usa.csv'
INTO TABLE users
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


# Comprovo els registres de la taula "users".
SELECT *
FROM users;


# Creo la taula "transactions"
CREATE TABLE IF NOT EXISTS transactions (
	transaction_id VARCHAR(255) PRIMARY KEY,
	card_id VARCHAR(15) ,
	company_id VARCHAR(15), 
	timestamp TIMESTAMP,
	amount DECIMAL(10,2),
	declined BOOLEAN,
	product_ids VARCHAR(25),
	user_id VARCHAR(5),
	lat FLOAT,
	longitude FLOAT,
	FOREIGN KEY (company_id) REFERENCES companies(company_id), 
	FOREIGN KEY (card_id) REFERENCES credit_cards(card_id),
	FOREIGN KEY (user_id) REFERENCES users(user_id)
    );
    
# Carrego les dades a "transactions"
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


#Comprovo que la taula s'ha carregat correctament
SELECT * 
FROM transactions;





/*- Exercici 1
Realitza una subconsulta que mostri tots els usuaris amb més de 30 transaccions utilitzant almenys 2 taules.*/

# Amb JOIN
SELECT u.user_id, u.name, u.surname, COUNT(t.transaction_id) as Total_transaccions
FROM users u
JOIN transactions t ON t.user_id = u.user_id
GROUP BY u.user_id, u.name, u.surname
HAVING Total_transaccions >= 30
ORDER BY Total_transaccions;



# Amb subconsulta
SELECT u.user_id, u.name, u.surname
FROM users u
WHERE u.user_id IN (SELECT t.user_id
			FROM transactions t
			GROUP BY user_id
			HAVING COUNT(t.transaction_id) >= 30);
            



/*- Exercici 2
Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.*/

# Join i subconsulta
SELECT cc.iban, ROUND(AVG(t.amount), 2) as mitjana_import
FROM credit_cards cc
JOIN transactions t
ON t.card_id = cc.card_id
WHERE t.company_id = (SELECT company_id
					FROM companies
					WHERE company_name = 'Donec Ltd')
GROUP BY cc.iban;

# 3 joins 
SELECT cc.iban, ROUND(AVG(t.amount), 2) as mitjana_import
FROM credit_cards cc
JOIN transactions t
ON t.card_id = cc.card_id
JOIN companies c
on c.company_id = t.company_id
WHERE company_name = 'Donec Ltd'
GROUP BY cc.iban;

/*Sprint 4 - Nivell 2

Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les últimes tres transaccions van ser declinades i genera la següent consulta:*/

# Creo la taula "estat_targetes"

CREATE TABLE estat_targetes 
			(card_id VARCHAR(15) PRIMARY KEY,
			estat ENUM('activa', 'no activa') NOT NULL);


# Creo les instruccions per afegir les targetes que tenen més de tres transaccions declinades a la nova taula.
INSERT INTO estat_targetes (card_id, estat)
SELECT card_id, 
	CASE 
	WHEN COUNT(CASE WHEN declined = 1 THEN 1 END) >= 3 
	THEN 'no activa'
	ELSE 'activa' 
	END AS estat
FROM (SELECT card_id, declined
	FROM (SELECT card_id, declined, ROW_NUMBER()
    OVER (PARTITION BY card_id ORDER BY timestamp DESC) AS Num_tr
    FROM transactions) subconsulta1
    WHERE Num_tr <= 3) subconsulta_transaccions
GROUP BY card_id;


SELECT *
FROM estat_targetes
LIMIT 10;


# Quantes targetes estan actives?

SELECT COUNT(*) as Núm_targetes_actives
FROM estat_targetes;
