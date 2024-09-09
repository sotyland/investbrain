#!/bin/bash

cd /var/www/app

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    OWNER=$(stat -f '%Su' storage)
else
    # Linux
    OWNER=$(stat -c '%U' storage)
fi

echo "====================== Running entrypoint script...  ====================== "
if [ ! -f ".env" ]; then
    echo " > Ope, gotta create an .env file!"

    cp .env.example .env
fi

echo "====================== Checking for updates...  ====================== "
/usr/bin/git pull

echo "====================== Installing Composer dependencies...  ====================== "
/usr/local/bin/composer install

echo "====================== Validating environment...  ====================== "
if [ "$OWNER" != "www-data" ]; then
    echo " > Setting correct permissions for storage directory..."
    chown -R www-data:www-data storage
fi

if ( ! grep -q "^APP_KEY=" ".env" || grep -q "^APP_KEY=$" ".env"); then
    echo " > Ah, APP_KEY is missing in .env file. Generating a new key!"
    
    /usr/local/bin/php artisan key:generate --force
fi

echo "====================== Installing NPM dependencies and building frontend...  ====================== "
/usr/bin/npm install 
/usr/bin/npm run build 

echo "====================== Running migrations...  ====================== "
/usr/local/bin/php artisan migrate --force

echo "====================== Running seeders...  ====================== "
/usr/local/bin/php artisan seed:market-data

echo "====================== Spinning up Supervisor daemon...  ====================== "
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
