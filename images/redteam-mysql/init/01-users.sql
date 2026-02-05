-- CYROID Red Team Lab - MariaDB Users
-- Create additional users with various access levels

-- Web application user (for WordPress)
CREATE USER IF NOT EXISTS 'webapp'@'%' IDENTIFIED BY 'WebApp123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'webapp'@'%';

-- Backup user (read-only)
CREATE USER IF NOT EXISTS 'backup'@'%' IDENTIFIED BY 'Backup2024';
GRANT SELECT ON *.* TO 'backup'@'%';

FLUSH PRIVILEGES;
