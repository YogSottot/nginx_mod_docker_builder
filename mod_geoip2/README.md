# GeoIP2 для AlmaLinux 9

Сборка HTTP-модуля leev/ngx_http_geoip2_module 3.4 для nginx 1.26.3 из
AppStream AlmaLinux 9 (поток `nginx:1.26`). Настройки находятся в `.env`.
Нужны Docker, fpm и rpmbuild на хосте. По умолчанию собирается x86_64.

```sh
cd mod_geoip2
make almalinux-9
```

RPM появится в `../rpm/almalinux-9/x86_64/`, файлы пакета — в
`../fpm/nginx-mod-http-geoip2/almalinux-9/`.

Сборщик устанавливает nginx из репозитория ОС, берёт исходники nginx той же
версии с nginx.org и выполняет `make modules` с `--with-compat`.
Во время сборки `nginx -t` проверяет загрузку модуля бинарным файлом из ОС.
RPM зависит от версии `nginx-core` без привязки к релизу пакета
(например, `nginx-core = 2:1.26.3`) и libmaxminddb.
Обновления релиза пакета в пределах nginx 1.26.3 не требуют пересборки модуля.
При изменении самой версии nginx модуль следует пересобрать.

Установка на сервере:

```sh
sudo dnf module enable nginx:1.26
sudo dnf install ./nginx-mod-http-geoip2-3.4-2.el9.x86_64.rpm
sudo nginx -t
sudo systemctl reload nginx
```

Файл `/usr/share/nginx/modules/mod-http-geoip2.conf` подключает модуль через
стандартный include AlmaLinux в основном контексте nginx.conf. Если этот
include удалён, добавьте его или директиву
`load_module /usr/lib64/nginx/modules/ngx_http_geoip2_module.so;` вручную.

Базы `.mmdb` в пакет не входят. Примеры настройки `geoip2` приведены в
[документации модуля](https://github.com/leev/ngx_http_geoip2_module).
