-- CYROID Red Team Lab - MySQL Users
-- Create additional users with various access levels

-- Web application user (for WordPress)
CREATE USER 'webapp'@'%' IDENTIFIED BY 'WebApp123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'webapp'@'%';

-- Backup user (read-only)
CREATE USER 'backup'@'%' IDENTIFIED BY 'Backup2024';
GRANT SELECT ON *.* TO 'backup'@'%';

-- Allow root from anywhere (intentionally insecure)
CREATE USER 'root'@'%' IDENTIFIED BY 'DBr00t2024!';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
