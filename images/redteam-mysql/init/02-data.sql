-- CYROID Red Team Lab - Sample Data

-- Create internal database with sensitive data
CREATE DATABASE IF NOT EXISTS internal_data;
USE internal_data;

-- Employee credentials table (discovered via SQLi or direct access)
CREATE TABLE employee_credentials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50),
    password VARCHAR(100),
    department VARCHAR(50),
    notes TEXT
);

INSERT INTO employee_credentials (username, password, department, notes) VALUES
('jsmith', 'Summer2024', 'IT', 'IT admin, has server access'),
('mwilliams', 'Welcome123', 'HR', 'New employee, needs password change'),
('svc_backup', 'Backup2024', 'Service', 'Backup service account'),
('svc_deploy', 'Deploy2024!', 'Service', 'CI/CD deployment account'),
('admin', 'Adm1n2024', 'IT', 'Domain administrator - EMERGENCY ONLY');

-- Server inventory
CREATE TABLE servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(50),
    ip_address VARCHAR(15),
    purpose VARCHAR(100),
    admin_password VARCHAR(100)
);

INSERT INTO servers (hostname, ip_address, purpose, admin_password) VALUES
('dc01', '172.16.2.12', 'Domain Controller', 'See AD admin'),
('fileserver', '172.16.2.10', 'File Server', 'FileAdmin2024'),
('db01', '172.16.2.40', 'Database Server', 'DBr00t2024!'),
('jenkins', '172.16.1.40', 'CI/CD Server', 'admin (default)');

-- Create WordPress database
CREATE DATABASE IF NOT EXISTS wordpress;
