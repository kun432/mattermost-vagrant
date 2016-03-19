CREATE DATABASE `mattermost` DEFAULT CHARACTER SET utf8mb4;
CREATE USER 'mmuser'@'localhost';
GRANT ALL ON `mattermost`.* TO 'mmuser'@'localhost' IDENTIFIED BY 'mmuser_password';
