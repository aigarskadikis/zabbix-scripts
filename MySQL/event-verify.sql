


SHOW PROCESSLIST; 


SET GLOBAL event_scheduler = ON;
SELECT @@global.event_scheduler;


SELECT * FROM INFORMATION_SCHEMA.events\G



DELIMITER $$
 
USE `zabbix`$$

CREATE EVENT IF NOT EXISTS `e_part_manage`
       ON SCHEDULE EVERY 1 DAY
       STARTS '2018-06-11 15:06:00'
       ON COMPLETION PRESERVE
       ENABLE
       COMMENT 'Creating and dropping partitions'
       DO BEGIN
            CALL zabbix.drop_partitions('zabbix');
            CALL zabbix.create_next_partitions('zabbix');
       END$$
DELIMITER ;

