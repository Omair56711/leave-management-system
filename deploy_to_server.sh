#!/bin/bash

# سكريبت نشر نظام إدارة الإجازات على خادم الويب

echo "بدء عملية نشر نظام إدارة الإجازات على خادم الويب..."

# تحديد المسارات
SOURCE_DIR="/home/ubuntu/leave_system_website"
DEPLOY_DIR="/var/www/leave_system"

# التأكد من وجود مجلد النشر
if [ ! -d "$DEPLOY_DIR" ]; then
    echo "إنشاء مجلد النشر..."
    mkdir -p $DEPLOY_DIR
    echo "✓ تم إنشاء مجلد النشر بنجاح"
else
    echo "مجلد النشر موجود بالفعل، سيتم تحديث الملفات"
fi

# نسخ ملفات الواجهة الأمامية
echo "نسخ ملفات الواجهة الأمامية..."
cp -r $SOURCE_DIR/*.html $SOURCE_DIR/css $DEPLOY_DIR/
echo "✓ تم نسخ ملفات الواجهة الأمامية بنجاح"

# إنشاء مجلد للواجهة الخلفية
API_DIR="$DEPLOY_DIR/api"
if [ ! -d "$API_DIR" ]; then
    mkdir -p $API_DIR
fi

# نسخ ملفات الواجهة الخلفية
echo "نسخ ملفات الواجهة الخلفية..."
cp -r $SOURCE_DIR/api/* $API_DIR/
echo "✓ تم نسخ ملفات الواجهة الخلفية بنجاح"

# تنفيذ ملف SQL لإنشاء قاعدة البيانات
echo "إنشاء هيكل قاعدة البيانات..."
DB_NAME="leave_management_system"
DB_USER="leave_admin"
DB_PASS="Secure_Password_2025"

if [ -f "$SOURCE_DIR/api/database.sql" ]; then
    mysql -u $DB_USER -p$DB_PASS $DB_NAME < $SOURCE_DIR/api/database.sql
    echo "✓ تم إنشاء هيكل قاعدة البيانات بنجاح"
else
    echo "⚠️ ملف قاعدة البيانات غير موجود، يرجى التحقق من المسار"
fi

# ضبط صلاحيات الملفات
echo "ضبط صلاحيات الملفات..."
chown -R www-data:www-data $DEPLOY_DIR
chmod -R 755 $DEPLOY_DIR
chmod -R 644 $DEPLOY_DIR/*.html $DEPLOY_DIR/css/*.css
chmod -R 755 $DEPLOY_DIR/api
echo "✓ تم ضبط صلاحيات الملفات بنجاح"

# إنشاء ملف .htaccess للواجهة الأمامية
echo "إنشاء ملف .htaccess للواجهة الأمامية..."
cat > $DEPLOY_DIR/.htaccess << EOF
# ملف .htaccess للواجهة الأمامية
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    
    # إعادة توجيه HTTP إلى HTTPS
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    
    # ضغط الملفات
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/x-javascript application/json
    </IfModule>
    
    # تخزين مؤقت للملفات الثابتة
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType text/css "access plus 1 month"
        ExpiresByType application/javascript "access plus 1 month"
    </IfModule>
</IfModule>
EOF
echo "✓ تم إنشاء ملف .htaccess للواجهة الأمامية بنجاح"

# إنشاء ملف .htaccess للواجهة الخلفية
echo "إنشاء ملف .htaccess للواجهة الخلفية..."
cat > $API_DIR/.htaccess << EOF
# ملف .htaccess للواجهة الخلفية
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /api/
    
    # إعادة توجيه جميع الطلبات إلى index.php
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ index.php/$1 [L]
</IfModule>
EOF
echo "✓ تم إنشاء ملف .htaccess للواجهة الخلفية بنجاح"

# إعادة تشغيل خدمات الويب
echo "إعادة تشغيل خدمات الويب..."
systemctl restart apache2
systemctl restart mysql
echo "✓ تم إعادة تشغيل خدمات الويب بنجاح"

echo "تم نشر نظام إدارة الإجازات على خادم الويب بنجاح!"
echo "يمكن الوصول إلى النظام من خلال: https://leave.company.com/"
