CREATE  TABLE IF NOT EXISTS `quiz_passed_players` (
  `steam` VARCHAR(45) NOT NULL ,
  `lastConnected` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`steam`) )
ENGINE = InnoDB;

