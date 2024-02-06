CREATE TABLE data_user (
 	id INT GENERATED ALWAYS AS IDENTITY,
	user_name bytea NOT NULL,
	user_password bytea NOT NULL,
	PRIMARY KEY(id)
);


CREATE TABLE data_user_audit (
	id INT GENERATED ALWAYS AS IDENTITY,
	user_id INT NOT NULL,
	old_user_name bytea NOT NULL,
 	old_user_password bytea NOT NULL,
	status VARCHAR(10) NOT NULL,
	changed_on TIMESTAMP NOT NULL
);


-- function to encrypt data user
CREATE OR REPLACE FUNCTION encrypt_data(user_data text, password text) RETURNS bytea AS $$
BEGIN
	RETURN pgp_sym_encrypt(user_data, password, 'compress-algo=1, cipher-algo=aes256');
END;
$$ LANGUAGE plpgsql;


-- function data change
CREATE OR REPLACE FUNCTION log_data_user_changes()
	RETURNS TRIGGER 
	LANGUAGE PLPGSQL
	AS
$$
BEGIN
	IF NEW.user_name <> OLD.user_name AND NEW.user_password <> OLD.user_password THEN
		 INSERT INTO data_user_audit(user_id,old_user_name,old_user_password,status,changed_on)
		 VALUES(OLD.id,OLD.user_name,OLD.user_password,'UPDATED',now());
	END IF;

	RETURN NEW;
END;
$$


-- trigger data chage
CREATE OR REPLACE TRIGGER log_data_user_changes
	BEFORE UPDATE
	ON data_user
	FOR EACH ROW
	EXECUTE PROCEDURE log_data_user_changes();


-- insert encrypted user
INSERT INTO data_user (user_name, user_password)
VALUES (encrypt_data('wisnu bayu', 'admin_password'), encrypt_data('pswwisnu', 'admin_password'));


-- update user data
UPDATE data_user
SET
user_name = encrypt_data(
 	'wisnu bayu',
 	'admin_password'
),
user_password = encrypt_data(
	'pswwisnubaru',
	'admin_password'
)
WHERE id = 1;


-- delete user
DELETE FROM data_user WHERE id = 1;


-- select data only
SELECT * FROM data_user


-- read decrypted data
SELECT 
id, 
pgp_sym_decrypt(user_name, 'admin_password') AS user_name, 
pgp_sym_decrypt(user_password, 'admin_password') AS user_password
FROM data_user;


-- select audit only
SELECT * FROM data_user_audit;


-- read decrypted audit
SELECT 
id, 
user_id,
pgp_sym_decrypt(old_user_name, 'admin_password') AS old_user_name, 
pgp_sym_decrypt(old_user_password, 'admin_password') AS old_user_password,
status,
changed_on
FROM data_user_audit;