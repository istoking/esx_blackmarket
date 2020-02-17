CREATE TABLE `blackmarket` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`store` varchar(100) NOT NULL,
	`item` varchar(100) NOT NULL,
	`price` int(11) NOT NULL,

	PRIMARY KEY (`id`)
);

INSERT INTO `blackmarket` (store, item, price) VALUES
	('blackmarket', 'yusuf', 3000),
	('blackmarket', 'grip', 1200),
	('blackmarket', 'flashlight', 800),
	('blackmarket', 'silencer', 3500),
	('blackmarket', 'bulletproof', 2500),
	('blackmarket', 'magazine', 1500),
	('blackmarket', 'scope', 1500),
	('blackmarket', 'clip', 250)
;

INSERT INTO `items` (`name`, `label`, `limit`, `rare`, `can_remove`) VALUES 
('yusuf', 'Deluxe Skin', 5, 0, 1),
('grip', 'Grip', 5, 0, 1),
('flashlight', 'Flashlight', 5, 0, 1),
('silencer', 'Silencer', 5, 0, 1),
('bulletproof', 'Bullet-Proof Vest', 5, 0, 1),
('magazine', 'Extended Magazine', 5, 0, 1),
('scope', 'Weapon Scope', 5, 0, 1),
('clip', 'Box of Ammo', 5, 0, 1);