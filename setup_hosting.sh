#!/bin/bash

# سكريبت إعداد بيئة استضافة الويب لنظام إدارة الإجازات

echo "بدء إعداد بيئة استضافة الويب لنظام إدارة الإجازات..."

# إنشاء مجلد للاستضافة
HOSTING_DIR="/var/www/leave_system"
echo "إنشاء مجلد الاستضافة: $HOSTING_DIR"

# التأكد من وجود المجلد أو إنشائه
if [ ! -d "$HOSTING_DIR" ]; then
    echo "إنشاء مجلد الاستضافة..."
    mkdir -p $HOSTING_DIR
    echo "✓ تم إنشاء مجلد الاستضافة بنجاح"
else
    echo "مجلد الاستضافة موجود بالفعل، سيتم تحديث الملفات"
fi

# تثبيت متطلبات الخادم
echo "تثبيت متطلبات الخادم..."
apt-get update
apt-get install -y apache2 php php-mysql php-mbstring php-xml php-curl mysql-server certbot python3-certbot-apache

# تكوين Apache
echo "تكوين خادم Apache..."
cat > /etc/apache2/sites-available/leave_system.conf << EOF
<VirtualHost *:80>
    ServerName leave.company.com
    ServerAdmin webmaster@company.com
    DocumentRoot $HOSTING_DIR
    
    <Directory $HOSTING_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/leave_system_error.log
    CustomLog \${APACHE_LOG_DIR}/leave_system_access.log combined
</VirtualHost>
EOF

# تفعيل الموقع
echo "تفعيل الموقع..."
a2ensite leave_system.conf
a2enmod rewrite
systemctl reload apache2

# إعداد قاعدة البيانات
echo "إعداد قاعدة البيانات..."
DB_NAME="leave_management_system"
DB_USER="leave_admin"
DB_PASS="Secure_Password_2025"

# إنشاء قاعدة البيانات والمستخدم
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# إنشاء ملف تكوين قاعدة البيانات
CONFIG_DIR="$HOSTING_DIR/api/config"
mkdir -p $CONFIG_DIR

echo "إنشاء ملف تكوين قاعدة البيانات..."
cat > $CONFIG_DIR/database.php << EOF
<?php
// ملف تكوين قاعدة البيانات
return [
    'host' => 'localhost',
    'username' => '$DB_USER',
    'password' => '$DB_PASS',
    'database' => '$DB_NAME',
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci',
];
EOF

# إعداد شهادة SSL
echo "إعداد شهادة SSL..."
# في بيئة الإنتاج، يجب استخدام الأمر التالي:
# certbot --apache -d leave.company.com

# إعداد جدار الحماية
echo "إعداد جدار الحماية..."
ufw allow 'Apache Full'
ufw allow ssh

# إعداد النسخ الاحتياطي التلقائي
echo "إعداد النسخ الاحتياطي التلقائي..."
BACKUP_DIR="/var/backups/leave_system"
mkdir -p $BACKUP_DIR

cat > /etc/cron.daily/leave_system_backup << EOF
#!/bin/bash
DATE=\$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/leave_system_\$DATE.sql"
mysqldump $DB_NAME > \$BACKUP_FILE
tar -czf "$BACKUP_DIR/leave_system_files_\$DATE.tar.gz" $HOSTING_DIR
find $BACKUP_DIR -name "leave_system_*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "leave_system_files_*.tar.gz" -mtime +7 -delete
EOF

chmod +x /etc/cron.daily/leave_system_backup

# إعداد مراقبة الأداء
echo "إعداد مراقبة الأداء..."
apt-get install -y prometheus-node-exporter

echo "تم إعداد بيئة استضافة الويب بنجاح!"
echo "الخطوة التالية هي نشر نظام إدارة الإجازات على الخادم."
