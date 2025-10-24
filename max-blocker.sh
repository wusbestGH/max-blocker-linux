#!/usr/bin/bash

HOST="/etc/hosts"
BACKUP_USER=$(logname) # Нужно для того чтобы копировать в домашнюю директория даже под судо
HOME_DIR=$(getent passwd "$BACKUP_USER" | cut -d: -f6) # Нужно для того чтобы копировать в домашнюю директория даже под судо
BACKUP_HOST=$HOME_DIR/max-backup-hosts # Путь для бэкапа

# ==================
# Статусы аргументов
# ==================

IS_DEBUG="F" # F - False / T - True
IS_HELP="F"
IS_STATUS="F"
IS_BLOCK="F"
IS_BLOCK_API="F"
IS_CP_HOSTS="F"
IS_UNBLOCK="F"
IS_NOLOGO="F"

# =======
# Логотип
# =======
logo() {
    cat << 'EOF'
=======================================================================

        █████████
     ███████████████
   ██████████████████
  ███████      ███████         ████     ████     █████  ██  ███    ███
 ███████         ██████        █████   █████   ███    ████   ███  ███
 ██████           █████        ██ ██   ██ ██  ███      ███    ██████
 ██████           █████        ██  ██ ██  ██  ███       ██    ██████
 ██████          ██████        ██  █████  ██  ████     ███   ███  ███
  █████        ███████         ██   ███   ██    ███████ ██  ███    ███
  ███████████████████
  ██████████████████
   ████  ████████

=======================================================================
Блокировщик Макса
EOF
}

# ======
# Помощь
# ======
get_help() {
    echo "Справка:"
    echo "Данный скрипт даёт вам заблокировать (пока только домены, клиент MAX я не хочу рисковать к себе скачивать для теста) MAX чтобы ваша класуха не смогла вам навязать шпионский и проклятый MAX"
    echo "--help      Помощь по скрипту"
    echo "--status    Проверка статуса блокировки"
    echo "--block     Блокирует все домены Макса (требует sudo)"
    echo "--block-api Блокирует API Макса (рекомендуется так как менее палевно) (требует sudo)"
    echo "--cp-hosts  Создает бэкап файла /etc/hosts в ~/max-backup-hosts"
    echo "--unblock   Разблокирует все домены Макса (но не надо, пожалуйста)"
    echo "--nologo    Убирает стартовый логотип"
}

# Блокировка только бекенда MAX
block_backend_max() {
echo "Вы выбрали заблокировать API MAX"

if [[ $EUID -eq 0 ]]; then # Проверка суперпользователя

    if grep "$HOST" -q -e "ws-api.oneme.ru" | grep "$HOST" -q -e "trk.mail.ru"; then # Проверка заблокирован ли уже API
        echo "Вы уже заблокировали..."
    else # В ином случае блокируем
        sudo echo -e "\n127.0.0.1 ws-api.oneme.ru #max-back\n127.0.0.1 trk.mail.ru" >> $HOST
    fi

else
    echo "Вы не под рутом. Отмена..."
    exit 1
fi

}

# Блокировка сайта MAX
block_max() {
echo "Вы выбрали заблокировать сайт MAX"
if [[ $EUID -eq 0 ]]; then # Проверка суперпользователя

    if grep "$HOST" -q -e "max.ru" | grep "$HOST" -q -e "web.max.ru" | grep "$HOST" -q -e "download.max.ru" | grep "$HOST" -q -e "ws-api.oneme.ru" | grep "$HOST" -q -e "trk.mail.ru"; then # Проверка заблокирован ли уже весь сайт
        echo "Вы уже заблокировали..."
    else # В ином случае блокируем
        sudo echo -e "\n127.0.0.1 ws-api.oneme.ru #max\n127.0.0.1 max.ru\n127.0.0.1 web.max.ru\n127.0.0.1 download.max.ru\n127.0.0.1 trk.mail.ru" >> $HOST
    fi
else # Если не суперпользователь то отмена выполнения
    echo "Вы не под рутом. Отмена..."
    exit 1
fi
}

# Разблокировать MAX (не надо это делать...)
unblock_max() {
echo "Вы выбрали разблокировать MAX (зачем...)"
if [[ $EUID -eq 0 ]]; then # Проверка суперпользователя
    sudo sed -i "/ws-api\.oneme\.ru\|trk\.mail\.ru\|max\.ru\|web\.max\.ru\|download\.max\.ru/d" $HOST
else # Если не суперпользователь то отмена выполнения
    echo "Вы не под рутом. Отмена..."
    exit 1
fi
}

# Проверка блокировки
status() {
echo "Вы выбрали проверить блокировку"

if grep "$HOST" -q -e "max.ru" | grep "$HOST" -q -e "web.max.ru" | grep "$HOST" -q -e "download.max.ru" | grep "$HOST" -q -e "ws-api.oneme.ru" | grep "$HOST" -q -e "trk.mail.ru"; then # Проверка на весь сайт
    echo -e "\033[1;32mУ вас заблокирован весь сайт MAX\033[0m"
elif grep "$HOST" -q -e "ws-api.oneme.ru" | grep "$HOST" -q -e "trk.mail.ru"; then # Проверка только API
    echo -e "\033[1;32mУ вас заблокирован API MAX\033[0m"
else
    echo -e "\033[1;31mУ вас отсутствует блокировка MAX!\033[0m" # Если отсутствует блокировка
fi

}

cp_hosts() {
echo "Вы также выбрали сделать бэкап '$HOST'"
echo $HOST $BACKUP_HOST
cp -f $HOST $BACKUP_HOST
}

# ===================
# Проверка аргументов
# ===================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) IS_HELP="T" ;;
        --status) IS_STATUS="T" ;;
        --block) IS_BLOCK="T" ; IS_BLOCK_API="F" ; IS_UNBLOCK="F" ;;
        --block-api) IS_BLOCK="F" ; IS_BLOCK_API="T" ; IS_UNBLOCK="F" ;;
        --cp-hosts) IS_CP_HOSTS="T" ;;
        --unblock) IS_BLOCK="F" ; IS_BLOCK_API="F" ; IS_UNBLOCK="T" ;;
        --nologo) IS_NOLOGO="T" ;;
        *) break ;; # Если неверные аргументы
    esac
    shift
done

# ===================
# Основное выполнение
# ===================
if [ "$IS_NOLOGO" = "T" ]; then # Проверяем надо ли выводить логотип
    :
else
    logo
fi

if [ "$IS_HELP" = "T" ]; then # Проверяем требуем ли справку
    get_help
    exit 0
fi

if [ "$IS_STATUS" = "T" ]; then # Проверяем требуем ли мы проверить статус блокировки
    status
    exit 0
fi

if [ "$IS_CP_HOSTS" = "T" ]; then # Проверяем требуем ли мы копировать hosts
    cp_hosts
fi

if [ "$IS_BLOCK" = "T" ]; then # Проверяем требуем ли мы блокировать сайт MAX
    block_max
    exit 0
fi

if [ "$IS_BLOCK_API" = "T" ]; then # Проверяем требуем ли мы блокировать API MAX
    block_backend_max
    exit 0
fi

if [ "$IS_UNBLOCK" = "T" ]; then # Проверяем требуем ли мы разблокировать MAX
    unblock_max
    exit 0
fi

# Если нет аргументов
echo -e "\033[1;31mОшибка: Неправильные или отсутствуют аргументы\033[0m" ; get_help

exit 1
