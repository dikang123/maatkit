DROP DATABASE IF EXISTS issue_295;
CREATE DATABASE issue_295;
USE issue_295;

DROP TABLE IF EXISTS `t`;
CREATE TABLE `t` (
  a  INT NOT NULL,
  b  INT NOT NULL,
  PRIMARY KEY  (a),
  INDEX b_a (b, a)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
