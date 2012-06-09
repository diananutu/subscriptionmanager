-- MySQL dump 10.13  Distrib 5.5.22, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: subscription
-- ------------------------------------------------------
-- Server version	5.5.22-0ubuntu1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `extra_users`
--

DROP TABLE IF EXISTS `extra_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `extra_users` (
  `euid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sid` int(10) unsigned NOT NULL,
  `uid` int(10) unsigned NOT NULL,
  `status` enum('active','inactive') DEFAULT 'inactive',
  `invite_date` date DEFAULT NULL,
  `registered_date` date DEFAULT NULL,
  `parent_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`euid`),
  UNIQUE KEY `sid` (`sid`,`uid`),
  KEY `uid` (`uid`),
  KEY `parent_id` (`parent_id`),
  CONSTRAINT `extra_users_ibfk_1` FOREIGN KEY (`sid`) REFERENCES `subscriptions` (`sid`),
  CONSTRAINT `extra_users_ibfk_2` FOREIGN KEY (`uid`) REFERENCES `users` (`uid`),
  CONSTRAINT `extra_users_ibfk_3` FOREIGN KEY (`parent_id`) REFERENCES `users` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `extra_users`
--

LOCK TABLES `extra_users` WRITE;
/*!40000 ALTER TABLE `extra_users` DISABLE KEYS */;
INSERT INTO `extra_users` VALUES (1,1,1,'inactive','2012-05-11',NULL,2),(3,2,2,'active','2012-05-11','2012-05-22',2),(6,6,6,'inactive','2012-05-28',NULL,2),(7,6,8,'inactive','2012-05-28',NULL,2),(8,7,6,'active','2012-05-28','2012-05-28',2),(9,8,8,'inactive','2012-05-28',NULL,2),(11,7,8,'inactive','2012-05-28',NULL,2),(12,6,9,'active','2012-05-28','2012-05-28',2),(13,6,12,'inactive','2012-06-06',NULL,2),(14,6,13,'inactive','2012-06-06',NULL,2);
/*!40000 ALTER TABLE `extra_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `features`
--

DROP TABLE IF EXISTS `features`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `features` (
  `fid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `price` float NOT NULL DEFAULT '0',
  `feature_name` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`fid`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `features`
--

LOCK TABLES `features` WRITE;
/*!40000 ALTER TABLE `features` DISABLE KEYS */;
INSERT INTO `features` VALUES (1,10,'feature 1'),(2,9,'feature 2'),(3,5.6,'feature 3'),(4,11,'feature 4'),(5,9.9,'feature 5'),(6,11.99,'feature 6'),(7,11,'feature 7');
/*!40000 ALTER TABLE `features` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pack`
--

DROP TABLE IF EXISTS `pack`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pack` (
  `pid` int(10) unsigned NOT NULL,
  `fid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`pid`,`fid`),
  KEY `fid` (`fid`),
  CONSTRAINT `pack_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `products` (`pid`),
  CONSTRAINT `pack_ibfk_2` FOREIGN KEY (`fid`) REFERENCES `features` (`fid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pack`
--

LOCK TABLES `pack` WRITE;
/*!40000 ALTER TABLE `pack` DISABLE KEYS */;
INSERT INTO `pack` VALUES (1,1),(2,1),(3,1),(4,1),(5,1),(1,2),(2,2),(3,2),(5,2),(2,3),(3,3),(5,3),(1,4),(2,4),(3,4),(5,4),(2,5),(3,5),(5,5),(3,6);
/*!40000 ALTER TABLE `pack` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_hashes`
--

DROP TABLE IF EXISTS `password_hashes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password_hashes` (
  `hid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(10) unsigned NOT NULL,
  `sent_url` varchar(150) NOT NULL,
  `expiry_date` date NOT NULL,
  `active` int(1) DEFAULT '1',
  PRIMARY KEY (`hid`),
  KEY `uid` (`uid`),
  CONSTRAINT `password_hashes_ibfk_1` FOREIGN KEY (`uid`) REFERENCES `users` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_hashes`
--

LOCK TABLES `password_hashes` WRITE;
/*!40000 ALTER TABLE `password_hashes` DISABLE KEYS */;
INSERT INTO `password_hashes` VALUES (1,1,'0e98c9bf4240a0d00c788ed5ed3e33ef26486659','2012-06-08',1),(2,9,'847194d3de4c43edc8810fea5bb2905e70c9436a','2012-06-09',0),(3,9,'847194d3de4c43edc8810fea5bb2905e70c9436a','2012-06-09',1),(4,9,'847194d3de4c43edc8810fea5bb2905e70c9436a','2012-06-09',1),(5,9,'847194d3de4c43edc8810fea5bb2905e70c9436a','2012-06-09',1);
/*!40000 ALTER TABLE `password_hashes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_downgrades`
--

DROP TABLE IF EXISTS `product_downgrades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_downgrades` (
  `piud` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_pid` int(10) unsigned NOT NULL,
  `downgraded_pid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`piud`),
  KEY `parent_pid` (`parent_pid`),
  KEY `downgraded_pid` (`downgraded_pid`),
  CONSTRAINT `product_downgrades_ibfk_1` FOREIGN KEY (`parent_pid`) REFERENCES `products` (`pid`),
  CONSTRAINT `product_downgrades_ibfk_2` FOREIGN KEY (`downgraded_pid`) REFERENCES `products` (`pid`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_downgrades`
--

LOCK TABLES `product_downgrades` WRITE;
/*!40000 ALTER TABLE `product_downgrades` DISABLE KEYS */;
INSERT INTO `product_downgrades` VALUES (1,2,1),(2,3,1),(3,3,2),(4,4,1),(5,4,2),(6,4,3),(8,5,1),(9,5,2),(10,5,3),(11,5,4);
/*!40000 ALTER TABLE `product_downgrades` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_upgrades`
--

DROP TABLE IF EXISTS `product_upgrades`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_upgrades` (
  `piud` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `parent_pid` int(10) unsigned NOT NULL,
  `upgraded_pid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`piud`),
  KEY `parent_pid` (`parent_pid`),
  KEY `upgraded_pid` (`upgraded_pid`),
  CONSTRAINT `product_upgrades_ibfk_1` FOREIGN KEY (`parent_pid`) REFERENCES `products` (`pid`),
  CONSTRAINT `product_upgrades_ibfk_2` FOREIGN KEY (`upgraded_pid`) REFERENCES `products` (`pid`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_upgrades`
--

LOCK TABLES `product_upgrades` WRITE;
/*!40000 ALTER TABLE `product_upgrades` DISABLE KEYS */;
INSERT INTO `product_upgrades` VALUES (1,1,2),(2,1,3),(3,1,4),(4,1,5),(5,2,3),(6,2,4),(7,2,5),(8,3,4),(9,3,5),(10,4,5),(11,6,3),(12,6,4);
/*!40000 ALTER TABLE `product_upgrades` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `products` (
  `pid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `no_periods` int(5) DEFAULT NULL,
  `subscription_cost` float DEFAULT NULL,
  `period_type` enum('day','week','month','quarter','year') DEFAULT NULL,
  `auto_renew` enum('0','1') DEFAULT NULL,
  `trial_period` int(5) DEFAULT NULL,
  `additional_users` int(5) DEFAULT NULL,
  `details` varchar(300) DEFAULT NULL,
  `actions` varchar(300) DEFAULT NULL,
  `is_new` int(1) DEFAULT '0',
  `active` int(1) DEFAULT '1',
  `requires_card` int(1) DEFAULT '0',
  `currency` enum('USD','EUR','GBP') DEFAULT 'USD',
  `trial_period_type` enum('day','week','month','quarter','year') DEFAULT NULL,
  `description` varchar(50) DEFAULT NULL,
  `is_featured` int(1) DEFAULT '0',
  PRIMARY KEY (`pid`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (1,'Free trial',1,0,'day','0',0,NULL,NULL,NULL,0,1,0,'USD',NULL,'Description 1',0),(2,'Basic',1,200,'week','0',1,NULL,NULL,NULL,0,1,0,'USD',NULL,'Description 2',1),(3,'Pro',3,500,'month','0',NULL,5,NULL,NULL,0,1,0,'USD',NULL,'Description 3',1),(4,'Vip',1,800,'year','1',NULL,NULL,NULL,NULL,0,1,0,'USD',NULL,'Description 4',1),(5,'King',10,1000,'quarter','1',NULL,5,NULL,'2012-06-05T12:02:33 gigi@gigi.com deactivated | 2012-06-05T12:02:35 gigi@gigi.com activated | ',0,1,0,'USD',NULL,'Description 5',1),(6,'ecommerce1',2,15,'month',NULL,1,0,NULL,NULL,NULL,1,NULL,'USD','month','Description 6',0);
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subscriptions`
--

DROP TABLE IF EXISTS `subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subscriptions` (
  `sid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(10) unsigned NOT NULL,
  `uid` int(10) unsigned NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `renew` enum('A','M','C') DEFAULT NULL,
  `active` int(1) DEFAULT NULL,
  PRIMARY KEY (`sid`),
  KEY `pid` (`pid`),
  KEY `uid` (`uid`),
  CONSTRAINT `subscriptions_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `products` (`pid`),
  CONSTRAINT `subscriptions_ibfk_2` FOREIGN KEY (`uid`) REFERENCES `users` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subscriptions`
--

LOCK TABLES `subscriptions` WRITE;
/*!40000 ALTER TABLE `subscriptions` DISABLE KEYS */;
INSERT INTO `subscriptions` VALUES (1,2,2,'2012-04-10 00:00:00','2012-04-30 00:00:00','A',1),(2,2,1,'2012-04-10 00:00:00','2012-04-30 00:00:00',NULL,1),(5,2,1,'2012-05-23 00:00:00','2012-05-30 00:00:00',NULL,1),(6,3,2,'2012-05-27 00:00:00','2012-08-27 00:00:00',NULL,0),(7,3,2,'2012-08-28 00:00:00','2012-11-28 00:00:00',NULL,1),(8,3,2,'2012-11-29 00:00:00','2013-03-01 00:00:00',NULL,1),(9,4,2,'2012-06-06 00:00:00','2013-06-06 00:00:00',NULL,0),(10,4,2,'2012-06-06 00:00:00','2013-06-06 00:00:00',NULL,1);
/*!40000 ALTER TABLE `subscriptions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `uid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(20) DEFAULT NULL,
  `photo` varchar(50) DEFAULT NULL,
  `email` varchar(50) NOT NULL,
  `address` varchar(150) DEFAULT NULL,
  `phone` varchar(12) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `country` varchar(50) DEFAULT NULL,
  `county` varchar(50) DEFAULT NULL,
  `birthday` date DEFAULT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `password` varchar(20) NOT NULL,
  `signup_date` datetime DEFAULT NULL,
  `access` varchar(10) DEFAULT 'user',
  `active` int(1) DEFAULT '0',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'gogu gfd','/uploads/1.jpg','gigi@gigi.com','test','12346','askjh','Azerbaijan','Cabrayil Rayonu','1995-12-24','Do not dis','aaa','2012-05-04 11:48:28','admin',0),(2,'gogu1 gfd2','/uploads/2.jpg','gigis@gigis.com','test','12346','askjh','Afghanistan','Syunik\'','1994-09-13','Do not dis','qqq','2012-05-04 11:48:28','user',0),(3,'gg','dsgf','','','','','American Samoa','Rose Island','1995-12-24','male','213456',NULL,'user',0),(5,NULL,NULL,'mihai.marca@yahoo.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'user',0),(6,NULL,NULL,'mihai_mar_k@yahoo.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'aaaa',NULL,'user',0),(7,NULL,NULL,'mihai.marca@gmail.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'user',0),(8,NULL,NULL,'mihai.marca@evozon.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'user',0),(9,'Raul Matei','','raul.matei@evozon.com','str. Orizont, Nr. 3','0771026303','Dej','Romania',NULL,'1982-04-26','Male','popopo',NULL,'user',1),(10,'sdfsdf','/uploads/10.jpg','sdfdzsf@asddas.com','','','','Afghanistan',NULL,'2012-05-17','Do not dis','sdfdsfds',NULL,'user',0),(11,'dfgdfgdfg','/uploads/11.jpg','gigi@gigi.comdgfdsg','','','','Afghanistan',NULL,'2012-05-02','Do not dis','dfgdfgdf',NULL,'user',0),(12,NULL,NULL,'alexandru.strajeriu@evozon.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'user',0),(13,NULL,NULL,'test@test.test',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'',NULL,'user',0),(14,'fdsg5553eg564 r','/uploads/14.jpg','test.test@test.com','','','','Afghanistan',NULL,'2012-06-07','Male','freebird',NULL,'user',0);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-06-08 14:15:20
