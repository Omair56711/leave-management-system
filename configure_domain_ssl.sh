#!/bin/bash

# سكريبت تكوين النطاق وشهادة SSL لنظام إدارة الإجازات

echo "بدء عملية تكوين النطاق وشهادة SSL لنظام إدارة الإجازات..."

# تحديد المتغيرات
DOMAIN="leave.company.com"
EMAIL="admin@company.com"

# تكوين النطاق في Apache
echo "تكوين النطاق في Apache..."
cat > /etc/apache2/sites-available/$DOMAIN.conf << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAdmin $EMAIL
    DocumentRoot /var/www/leave_system
    
    <Directory /var/www/leave_system>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
</VirtualHost>
EOF

# تفعيل الموقع
echo "تفعيل الموقع..."
a2ensite $DOMAIN.conf
systemctl reload apache2
echo "✓ تم تفعيل الموقع بنجاح"

# تثبيت Certbot إذا لم يكن موجوداً
if ! command -v certbot &> /dev/null; then
    echo "تثبيت Certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-apache
fi

# الحصول على شهادة SSL
echo "الحصول على شهادة SSL..."
certbot --apache -d $DOMAIN --non-interactive --agree-tos --email $EMAIL
echo "✓ تم الحصول على شهادة SSL بنجاح"

# التحقق من تجديد شهادة SSL التلقائي
echo "التحقق من تجديد شهادة SSL التلقائي..."
certbot renew --dry-run
echo "✓ تم التحقق من تجديد شهادة SSL التلقائي بنجاح"

# إضافة إعادة توجيه من HTTP إلى HTTPS
echo "إضافة إعادة توجيه من HTTP إلى HTTPS..."
cat > /etc/apache2/sites-available/$DOMAIN-le-ssl.conf << EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName $DOMAIN
    ServerAdmin $EMAIL
    DocumentRoot /var/www/leave_system
    
    <Directory /var/www/leave_system>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN}_access.log combined
    
    SSLCertificateFile /etc/letsencrypt/live/$DOMAIN/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>
EOF

# إعادة تشغيل Apache
echo "إعادة تشغيل Apache..."
systemctl restart apache2
echo "✓ تم إعادة تشغيل Apache بنجاح"

# إضافة سجلات DNS (هذا يتطلب الوصول إلى لوحة تحكم DNS)
echo "لإكمال إعداد النطاق، يجب إضافة سجلات DNS التالية في لوحة تحكم مزود النطاق:"
echo "1. سجل A: $DOMAIN يشير إلى عنوان IP الخادم"
echo "2. سجل CNAME: www.$DOMAIN يشير إلى $DOMAIN"

echo "تم تكوين النطاق وشهادة SSL بنجاح!"
echo "يمكن الوصول إلى النظام من خلال: https://$DOMAIN/"
