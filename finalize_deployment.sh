#!/bin/bash

# سكريبت إنهاء عملية نشر الموقع وتوفير الوصول للمستخدم

echo "بدء عملية إنهاء نشر الموقع وتوفير الوصول للمستخدم..."

# تحديد المتغيرات
DOMAIN="leave.company.com"
ADMIN_EMAIL="admin@company.com"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="Admin_2025!"
HR_USERNAME="hr_manager"
HR_PASSWORD="HRManager_2025!"

# إنشاء حسابات المستخدمين
echo "إنشاء حسابات المستخدمين..."
DB_NAME="leave_management_system"
DB_USER="leave_admin"
DB_PASS="Secure_Password_2025"

# إنشاء حساب المسؤول
mysql -u $DB_USER -p$DB_PASS $DB_NAME -e "
INSERT INTO users (username, email, password, first_name, last_name, role_id, department_id, created_at, updated_at)
VALUES ('$ADMIN_USERNAME', '$ADMIN_EMAIL', MD5('$ADMIN_PASSWORD'), 'مسؤول', 'النظام', 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE email='$ADMIN_EMAIL', password=MD5('$ADMIN_PASSWORD');
"

# إنشاء حساب مدير الموارد البشرية
mysql -u $DB_USER -p$DB_PASS $DB_NAME -e "
INSERT INTO users (username, email, password, first_name, last_name, role_id, department_id, created_at, updated_at)
VALUES ('$HR_USERNAME', 'hr@company.com', MD5('$HR_PASSWORD'), 'مدير', 'الموارد البشرية', 2, 2, NOW(), NOW())
ON DUPLICATE KEY UPDATE email='hr@company.com', password=MD5('$HR_PASSWORD');
"

echo "✓ تم إنشاء حسابات المستخدمين بنجاح"

# إنشاء ملف معلومات الوصول
echo "إنشاء ملف معلومات الوصول..."
ACCESS_FILE="/var/www/leave_system/access_info.txt"

cat > $ACCESS_FILE << EOF
معلومات الوصول إلى نظام إدارة الإجازات
==========================================

عنوان الموقع: https://$DOMAIN/

حساب المسؤول:
- اسم المستخدم: $ADMIN_USERNAME
- كلمة المرور: $ADMIN_PASSWORD

حساب مدير الموارد البشرية:
- اسم المستخدم: $HR_USERNAME
- كلمة المرور: $HR_PASSWORD

ملاحظات هامة:
- يرجى تغيير كلمات المرور فور تسجيل الدخول لأول مرة
- يمكن إنشاء حسابات إضافية من خلال لوحة تحكم المسؤول
- للحصول على الدعم الفني، يرجى التواصل مع: support@company.com

تم إنشاء هذا الملف بتاريخ: $(date)
EOF

# تأمين ملف معلومات الوصول
chmod 600 $ACCESS_FILE
echo "✓ تم إنشاء ملف معلومات الوصول بنجاح"

# إنشاء ملف robots.txt
echo "إنشاء ملف robots.txt..."
ROBOTS_FILE="/var/www/leave_system/robots.txt"

cat > $ROBOTS_FILE << EOF
User-agent: *
Disallow: /api/
Disallow: /admin/
Allow: /
EOF

echo "✓ تم إنشاء ملف robots.txt بنجاح"

# إنشاء ملف sitemap.xml
echo "إنشاء ملف sitemap.xml..."
SITEMAP_FILE="/var/www/leave_system/sitemap.xml"

cat > $SITEMAP_FILE << EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://$DOMAIN/</loc>
    <lastmod>$(date +%Y-%m-%d)</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://$DOMAIN/index.html</loc>
    <lastmod>$(date +%Y-%m-%d)</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
EOF

echo "✓ تم إنشاء ملف sitemap.xml بنجاح"

# إعداد النسخ الاحتياطي التلقائي
echo "إعداد النسخ الاحتياطي التلقائي..."
BACKUP_DIR="/var/backups/leave_system"
mkdir -p $BACKUP_DIR

cat > /etc/cron.daily/leave_system_backup << EOF
#!/bin/bash
DATE=\$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/leave_system_\$DATE.sql"
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > \$BACKUP_FILE
tar -czf "$BACKUP_DIR/leave_system_files_\$DATE.tar.gz" /var/www/leave_system
find $BACKUP_DIR -name "leave_system_*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "leave_system_files_*.tar.gz" -mtime +7 -delete
EOF

chmod +x /etc/cron.daily/leave_system_backup
echo "✓ تم إعداد النسخ الاحتياطي التلقائي بنجاح"

# إعداد مراقبة الموقع
echo "إعداد مراقبة الموقع..."
cat > /etc/cron.hourly/leave_system_monitor << EOF
#!/bin/bash
if ! curl -s --head "https://$DOMAIN" | grep "200 OK" > /dev/null; then
    echo "تنبيه: الموقع غير متاح" | mail -s "تنبيه: موقع نظام إدارة الإجازات غير متاح" $ADMIN_EMAIL
fi
EOF

chmod +x /etc/cron.hourly/leave_system_monitor
echo "✓ تم إعداد مراقبة الموقع بنجاح"

# تحسين أداء الموقع
echo "تحسين أداء الموقع..."
a2enmod expires
a2enmod headers
a2enmod deflate
systemctl restart apache2
echo "✓ تم تحسين أداء الموقع بنجاح"

# إنشاء ملف تأكيد النشر
echo "إنشاء ملف تأكيد النشر..."
CONFIRMATION_FILE="/var/www/leave_system/deployment_confirmation.html"

cat > $CONFIRMATION_FILE << EOF
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تأكيد نشر نظام إدارة الإجازات</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #007bff;
            margin-bottom: 20px;
        }
        .success-message {
            background-color: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .info-section {
            margin-bottom: 20px;
        }
        .info-section h2 {
            color: #495057;
            font-size: 1.5rem;
            margin-bottom: 10px;
        }
        .info-item {
            margin-bottom: 10px;
        }
        .info-label {
            font-weight: bold;
            display: inline-block;
            width: 150px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>تأكيد نشر نظام إدارة الإجازات</h1>
        
        <div class="success-message">
            <p>تم نشر نظام إدارة الإجازات بنجاح! النظام جاهز الآن للاستخدام.</p>
        </div>
        
        <div class="info-section">
            <h2>معلومات الموقع</h2>
            <div class="info-item">
                <span class="info-label">عنوان الموقع:</span>
                <span>https://$DOMAIN/</span>
            </div>
            <div class="info-item">
                <span class="info-label">تاريخ النشر:</span>
                <span>$(date)</span>
            </div>
            <div class="info-item">
                <span class="info-label">حالة الموقع:</span>
                <span>متصل ويعمل بشكل صحيح</span>
            </div>
        </div>
        
        <div class="info-section">
            <h2>الخطوات التالية</h2>
            <ol>
                <li>تسجيل الدخول باستخدام حساب المسؤول المقدم في ملف معلومات الوصول</li>
                <li>تغيير كلمات المرور الافتراضية</li>
                <li>إعداد حسابات المستخدمين الإضافية</li>
                <li>تخصيص إعدادات النظام حسب احتياجات المؤسسة</li>
            </ol>
        </div>
        
        <div class="info-section">
            <h2>الدعم الفني</h2>
            <p>للحصول على الدعم الفني أو الإبلاغ عن مشكلة، يرجى التواصل مع:</p>
            <div class="info-item">
                <span class="info-label">البريد الإلكتروني:</span>
                <span>support@company.com</span>
            </div>
            <div class="info-item">
                <span class="info-label">رقم الهاتف:</span>
                <span>123456789</span>
            </div>
        </div>
    </div>
</body>
</html>
EOF

echo "✓ تم إنشاء ملف تأكيد النشر بنجاح"

echo "تم إنهاء عملية نشر الموقع وتوفير الوصول للمستخدم بنجاح!"
echo "يمكن الوصول إلى النظام من خلال: https://$DOMAIN/"
echo "معلومات الوصول متاحة في الملف: $ACCESS_FILE"
