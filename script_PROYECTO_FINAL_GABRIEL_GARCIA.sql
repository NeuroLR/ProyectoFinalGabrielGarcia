-- FUNCIONES DEL PROYECTO --
-- La función obtener_tarjeta se encarga de devolver todos los datos de la tarjeta del usuario
-- usando los parametros dni y es_cliente
DELIMITER //
CREATE FUNCTION `obtener_tarjeta`(dni varchar(20), es_cliente boolean) RETURNS int
DETERMINISTIC
BEGIN
	DECLARE card_id INT;
    DECLARE user_id INT;

	IF es_cliente THEN
		SET user_id = (SELECT client_id FROM clients WHERE DOCUMENT_NUMBER = dni);
		SET card_id = (SELECT client_card_information.CARD_ID
        FROM client_card_information
        INNER JOIN clients ON client_card_information.CLIENT_ID = user_id);
	ELSE
		SET user_id = (SELECT seller_id FROM seller WHERE DOCUMENT_NUMBER = dni);
		SET card_id = (SELECT seller_card_information.CARD_ID
        FROM seller_card_information
        INNER JOIN seller ON seller_card_information.SELLER_ID = user_id);
	END IF;
    
RETURN card_id;
END
// DELIMITER;
-- La funcion obtener_nombre_completo nos retorna el nombre completo del usuario que queramos pasando unicamente
-- su dni y si es cliente o no
DELIMITER //
CREATE FUNCTION `obtener_nombre_completo`(dni varchar(20), es_cliente boolean) RETURNS varchar(255)
DETERMINISTIC
BEGIN
	DECLARE resultado varchar(255);
    IF es_cliente THEN
		SET resultado = (SELECT FULLNAME FROM CLIENTS 
			WHERE DOCUMENT_NUMBER = dni);
	ELSE 
		SET resultado = (SELECT FULLNAME FROM SELLER 
        WHERE DOCUMENT_NUMBER = dni);
	END IF;
RETURN resultado;
END
// DELIMITER;

SELECT obtener_nombre_completo(43405039, true) AS nombreCompleto;

SELECT obtener_tarjeta(42906030, false) AS tarjeta;

-- VISTAS DEL PROYECTO -- 
-- Vista "informacion_del_cliente"
-- Se encarga de obtener todos los datos necesarios para la compra de un producto
-- estos datos son:
-- nombre completo, dni, direccion, codigo postal, numero de tarjeta, fecha de vencimiento de la tarjeta.
-- esta vista utiliza las tablas clients y client_card_information
CREATE OR REPLACE VIEW informacion_del_cliente AS 
	SELECT c.FULLNAME as nombreCompleto, c.DOCUMENT_NUMBER as DNI, c.ADDRESS as direccion, 
    c.POSTAL_CODE as codigoPostal, card.CARD_NUMBER as numTarjeta, card.CARD_EXPIRATION as fechaVencimiento 
	FROM clients c INNER JOIN 
    client_card_information card ON 
    c.CLIENT_ID = card.CLIENT_ID;
    
SELECT * from informacion_del_cliente;

-- VISTA publicaciones_subidas --
-- Se encarga de recopilar todos las publicaciones y el usuario del vendedor
-- Obtiene informacion del vendedor relevante para el cliente como la direccion y el email
-- Obtiene todos los detalles de la publicacion a mostrar como el titulo, precio, puntuacion
-- esta vista utiliza las tablas seller y posts
CREATE OR REPLACE VIEW publicaciones_subidas AS
	SELECT s.USERNAME as nombreUsuario, s.ADDRESS as direccion, s.EMAIL as email, p.TITLE as tituloPost,
    p.DESCRIPTION as descripcionPost, p.PRICE as precio, p.SCORE as puntuacion, p.FEATURES as caracteristicas
    FROM seller s JOIN
    posts p ON 
    s.SELLER_ID = p.SELLER_ID;

SELECT * from publicaciones_subidas;

CREATE OR REPLACE VIEW informacion_del_vendedor AS 
	SELECT v.FULLNAME as nombreCompleto, v.DOCUMENT_NUMBER as DNI, v.ADDRESS as direccion, 
    v.POSTAL_CODE as codigoPostal, card.CARD_NUMBER as numTarjeta, card.CARD_EXPIRATION as fechaVencimiento 
	FROM seller v INNER JOIN 
    seller_card_information card ON 
    v.SELLER_ID = card.SELLER_ID;
    
SELECT * from informacion_del_vendedor;

-- La vista comentarios_del_cliente se encarga de obtener todos los comentarios hechos por los clientes
CREATE OR REPLACE VIEW comentarios_del_cliente AS
	SELECT c.CLIENT_ID as clienteID,c.FULLNAME as nombreCompleto, c.USERNAME as nombreUsuario, c.EMAIL as email,
	com.TEXT as textoComentario, com.SCORE as puntaje, com.DATE as fechaPublicacion 
    FROM clients c INNER JOIN
    comment com ON
    c.CLIENT_ID = com.CLIENT_ID;
    
SELECT * FROM comentarios_del_cliente;

CREATE OR REPLACE VIEW mejores_productos AS 
	SELECT TITLE, PRICE, SCORE, FEATURES, DESCRIPTION, SELLER_ID FROM posts WHERE SCORE > 4;

SELECT * FROM mejores_productos;

-- STORED PROCEDURES --
-- El SP "publicaciones_guardadas" se encarga de obtener todos los datos del cliente incluyendo las publicaciones
-- que tenga guardadas.
-- Necesita un solo parametro que es el ID del cliente
DELIMITER //
CREATE PROCEDURE publicaciones_guardadas(IN clientId INT)
BEGIN
	SELECT * FROM clients c INNER JOIN saved_posts s
    ON c.CLIENT_ID AND s.CLIENTS_CLIENT_ID = clientId
    INNER JOIN posts p ON p.POST_ID = s.POSTS_POST_ID;
END; //

CALL publicaciones_guardadas(1);

-- Con el store procedure publicaciones_bien_puntuadas podemos saber que productos le gustaron a un cliente especifico
DELIMITER //
CREATE PROCEDURE publicaciones_bien_puntuadas (IN clientId INT)
BEGIN
	SELECT com.POST_ID as postId, com.SCORE as puntaje
    FROM clients c INNER JOIN comment com WHERE c.CLIENT_ID = clientId AND com.SCORE >4;
END //

CALL publicaciones_bien_puntuadas(1);

-- TRIGGERS --
DELIMITER //
CREATE TRIGGER clientes_backup BEFORE INSERT ON clients
FOR EACH ROW 
INSERT INTO backup_clientes 
(
	`USERNAME`,
	`DOCUMENT_TYPE`,
	`DOCUMENT_NUMBER`,
	`FULLNAME`,
	`POSTAL_CODE`,
	`ADDRESS`,
	`EMAIL`,
	`PASSWORD`
) VALUES
(
	NEW.USERNAME,
    NEW.DOCUMENT_TYPE,
    NEW.DOCUMENT_NUMBER,
    NEW.FULLNAME,
    NEW.POSTAL_CODE,
    NEW.ADDRESS,
    NEW.EMAIL,
    NEW.PASSWORD
)
//
SELECT * FROM backup_clientes;

DELIMITER //
CREATE TRIGGER vendedores_backup BEFORE INSERT ON seller
FOR EACH ROW 
INSERT INTO backup_vendedores
(
	`USERNAME`,
	`DOCUMENT_TYPE`,
	`DOCUMENT_NUMBER`,
	`FULLNAME`,
	`POSTAL_CODE`,
	`ADDRESS`,
	`EMAIL`,
	`PASSWORD`
) VALUES
(
	NEW.USERNAME,
    NEW.DOCUMENT_TYPE,
    NEW.DOCUMENT_NUMBER,
    NEW.FULLNAME,
    NEW.POSTAL_CODE,
    NEW.ADDRESS,
    NEW.EMAIL,
    NEW.PASSWORD
)
//

SELECT * FROM backup_vendedores;

-- TCL --
START TRANSACTION;
DELETE FROM client_card_information WHERE CLIENT_ID = 1;
SELECT * FROM client_card_information;
-- ROLLBACK; 
-- COMMIT;

START TRANSACTION;
INSERT INTO posts 
(`TITLE`,`DESCRIPTION`,`PRICE`,`SCORE`,`FEATURES`,`SELLER_ID`) 
VALUES ("Moto E22 64g 4gb ram", "celular", 79000, 4.2, "4gb ram", 1);

INSERT INTO posts 
(`TITLE`,`DESCRIPTION`,`PRICE`,`SCORE`,`FEATURES`,`SELLER_ID`) 
VALUES ("Smart tv Noblex", "televisor", 150000, 3.9, "43 pulgadas", 1);

INSERT INTO posts 
(`TITLE`,`DESCRIPTION`,`PRICE`,`SCORE`,`FEATURES`,`SELLER_ID`) 
VALUES ("Sommier Simmons", "colchon", 200000, 4.5, "190cmx140cm", 1);

INSERT INTO posts 
(`TITLE`,`DESCRIPTION`,`PRICE`,`SCORE`,`FEATURES`,`SELLER_ID`) 
VALUES ("Taladro Atornillador percutor", "taladro", 37000, 4.0, "color amarillo", 1);

SAVEPOINT save1;

INSERT INTO posts 
(`TITLE`,`DESCRIPTION`,`PRICE`,`SCORE`,`FEATURES`,`SELLER_ID`) 
VALUES ("Moto G23", "celular", 108000, 3.1, "128gb 4gb ram", 1);

INSERT INTO posts 
(`TITLE`,`DESCRIPTION`,`PRICE`,`SCORE`,`FEATURES`,`SELLER_ID`) 
VALUES ("Monitor Samsung", "monitor", 87000, 4.4, "24 pulgadas, color gris oscuro", 1);

INSERT INTO posts 
(`TITLE`,`DESCRIPTION`,`PRICE`,`SCORE`,`FEATURES`,`SELLER_ID`) 
VALUES ("Cinta de embalar 36u", "cinta", 25000, 4.7, "transparente, 48x100", 1);

INSERT INTO posts 
(`TITLE`,`DESCRIPTION`,`PRICE`,`SCORE`,`FEATURES`,`SELLER_ID`) 
VALUES ("Planchita de pelo", "planchita de pelo roja", 21000, 4.9, "alcanza los 230°C", 1);

SAVEPOINT save2;

-- RELEASE SAVEPOINT save1;
 
