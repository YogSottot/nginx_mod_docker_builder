# bx-nginx для EL7

Сборка бинарного RPM из SRPM Bitrix для EL9 в Docker на CentOS 7.
Нужны Docker и GNU Make на хосте; fpm не требуется. Целевая архитектура — x86_64.

```sh
cd bx_nginx
make centos-7
```

Настройки находятся в `.env`. `BX_NGINX_VERSION=1.30.8-1.el9` задаёт SRPM:
`https://repo.bitrix.info/dnf/SRPMS/bx-nginx-1.30.8-1.el9.src.rpm`.
`BUILD_DEBUG=1` дополнительно собирает пакет `bx-nginx-debug`.

Результат: `../rpm/centos-7/x86_64/bx-nginx-1.30.8-1.el7.x86_64.rpm`.
Адаптированный исходный RPM сохраняется в подкаталоге `SRPMS/`.

Сборщик скачивает SRPM самостоятельно. Локальные каталоги распакованных
исходников не используются и не изменяются; они исключены из Docker-контекста.
После сборки RPM устанавливается в контейнер, выполняются `nginx -V` и `nginx -t`.
Дополнительно проверяется конфигурация с директивами push-stream и Brotli.

`prepare-spec.py` адаптирует текущую ветку сборки EL9 к EL7, сохраняя
mod_zip, headers-more и Brotli из нового SRPM. OpenSSL заменяется на 1.1.1w,
HTTP/3 отключается, HTTP/2 остаётся включённым. Старые ветки EL7/EL8 spec
не используются: в них указаны другие версии nginx и отсутствующие в SRPM
архивы модулей. Push-stream скачивается из репозитория wandenberg отдельно;
его версия задаётся через `PUSH_STREAM_VERSION` в `.env`. Используется тег 0.6.0:
тег 0.5.6, соответствующий имени старого локального архива, в upstream отсутствует,
а указанная в исходном spec версия 0.4.1
не собирается с nginx 1.30.7 из-за изменений API заголовков nginx.
Для Brotli используется имеющийся `ngx_brotli-1.2.1.tgz`, отдельный архив
`ngx_brotli.tgz` не нужен. PageSpeed не добавляется.
Конфигурация, systemd unit, зависимости и скрипты установки
берутся из исходного spec. Флаги архитектуры заменяются на
`-march=x86-64 -mtune=generic`: это поддерживается GCC 4.8 из EL7 и не
привязывает пакет к процессору сборочной машины. В частности,
`-march=x86-64-v2` из нового spec GCC 4.8 не поддерживает.

Репозитории CentOS 7 используются из Vault. Для сборки Brotli устанавливается
CMake из официального бинарного архива, его версия также задаётся в `.env`.

## Установка через Ansible

Для стандартного Python 2.7 и yum на EL7 нужен `ansible-core 2.16.x` на
управляющей машине (Python 3.10–3.12). Более новые версии ansible-core
не поддерживают этот Python и модуль yum. См. [матрицу совместимости Ansible](https://docs.ansible.com/projects/ansible/latest/reference_appendices/release_and_maintenance.html)
и [документацию модуля yum для 2.16](https://docs.ansible.com/projects/ansible-core/2.16/collections/ansible/builtin/yum_module.html).

Скопируйте `inventory.example.ini` в свой inventory и укажите адрес сервера,
SSH-пользователя и при необходимости параметры sudo. Группа — `bx_nginx`.

```sh
ansible-playbook -i /path/to/inventory.ini bx_nginx/deploy.yml --ask-become-pass
```

Playbook сначала проверяет семейство RedHat, версию ОС 7, архитектуру x86_64
и systemd. Затем копирует RPM, устанавливает через yum, выполняет
`systemctl daemon-reload`, `nginx -t` и перезапускает nginx. При ошибке проверки
конфигурации задача перезапуска не выполняется. Серверы обрабатываются по одному;
ошибка останавливает дальнейшее развёртывание.

Путь к RPM по умолчанию вычисляется из `BX_NGINX_VERSION` в `.env`.
Другой пакет можно указать явно:

```sh
ansible-playbook -i /path/to/inventory.ini bx_nginx/deploy.yml \
  -e bx_nginx_rpm=/absolute/path/to/bx-nginx-1.30.8-1.el7.x86_64.rpm
```

Локальный RPM не подписан, поэтому проверка GPG при его установке отключена.
Штатные RPM-скрипты пакета выполняются при установке; в частности, `%postun`
предыдущего пакета может вызвать `service nginx upgrade` ещё до задач Ansible.
