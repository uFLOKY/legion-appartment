
CREATE TABLE IF NOT EXISTS `leagonappartment` (
  `id` int(11) NOT NULL,
  `isowned` int(11) DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `password` varchar(50) DEFAULT NULL,
  `ownername` mediumtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

