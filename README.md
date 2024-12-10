# TLGRM - скрипт оповещения в Телеграм и удалённого запуска функций, скриптов и команд RouterOS.

Скрипт обеспечивает отправку (трансляцию) записей журнала устройств Mikrotik в заданную Telegram-группу и удалённый запуск скриптов, функций и команд RouterOS. В скрипте использованы идеи и части кода разных авторов, найденные на просторах интернета. Код скрипта содержит всё необходимое для работы и не имеет зависимостей от сторонних функций и скриптов. Работосопособность скрипта проверялась на актуальных версиях RouterOS 6.49.++ и 7.16.++. Тело скрипта необходимо закинуть в 'System/Scripts' и настроить запуск в 'System/Sheduler' с требуемым периодом времени (типовое значение составляет 1 минуту).

Во время работы скрипт взаимодействует с заданной Телеграм-группой и при этом:
- реагирует на принятые команды из сообщений группы
- транслирует в группу потенциально интересные записи журнала устройства

## Особенности работы скрипта:
- формируемые скриптом сообщения дробятся по 4096 байтов
- поддерживается отправка сообщений с кириллическими символами (CP1251)
- сообщения, неотправленные из-за проблем с интернет-каналом, отсылаются после восстановления связи
- обрабатывается только ПОСЛЕДНЯЯ команда, отправленная пользователем в ТГ-группу
- поддерживается индивидуальная и групповая адресация команд пользователя
- трансляция единственной записи журнала производится одной строкой с ID роутера (без разделителя) для возможности чтения сообщения в шторке уведомлений без разблокировки мобильного устройства
- трансляция сообщений о подключении/отключении беспроводных клиентов производится в случаях, только когда для МАС-адреса из строки журнала:
    - отсутствует соответствующий IP-адрес в списке DHCP/Leases
    - назначен динамический IP-адрес в списке DHCP/Leases
    - назначен статический IP-адрес в списке DHCP/Leases и при этом комментарий к нему отсутствует
- контроль работы скрипта доступен в терминале по команде: /system script run tlgrm (где 'tlgrm' - имя скрипта)
- ID устройства должно состоять только из маленьких латинских букв и цифр

Отправка команды всем или одному конкретному роутеру, находящемуся в ТГ-группе, подразумевает отправку подготовленного специальным образом сообщения, при этом скрипт должен быть запущен на всех роутерах, которым может быть адресовано сообщение. Для отправки команды необходимо сформировать сообщение в виде текстовой строки специального формата: 
 - начало сообщения обозначается символом "/"
 - затем указывается ID устройства, которому адресовано сообщение (соответствует /system identity устройства). Отправка всем роутерам в ТГ-группе подразумевает указание в качестве адресата: forall. Для корректной работы имя устройства должно содержать ТОЛЬКО маленькие латинские буквы и цифры (!!!).
 - далее через символ подчеркивания или пробел указывается непосредственно команда. В качестве команды могут выступать: имя глобальной функции, имя скрипта или команда RouterOS.

Примеры строк с командами:
~~~ 
  /forall log warning [/system resource get uptime]
  /mikrotik system reboot
  /mikrotik1_wol
  /mikrot_ip_fir_fil_dis_[find_comment~"LAN"]
~~~
Настройки хранятся вначале скрипта и представляют собой преднастроенные переменные:
- **botID** "XXXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" - идентификатор бота
- **myChatID** "-XXXXXXXXX"  идентификатор чата
- **broadCast**, где false = реакция на команды, предназначенные только этому устройству; true = реакция на все принятые команды
- **launchScr**, где true = разрешение исполнения скриптов; false = запрет исполнения скриптов
- **launchFnc**, где true = разрешение использования глобальных функций; false = запрет использования функций
- **launchCmd**, где true = разрешение выполнения команд RouterOS; false = запрет выполнения команд RouterOS
- **sysInfo**,   где true = разрешение трансляции в ТГ-чат подозрительных событий журнала устройства; false = запрет трансляции событий журнала устройства
- **userInfo**,  где true = разрешение трансляции в ТГ-чат сообщений, сформированных по условиям пользователя; false = запрет трансляции пользовательских сообщений

Минимальная настройка скрипта сводится к указанию идентификаторов бота и группы: [botID и myChatID](https://1spla.ru/blog/telegram_bot_for_mikrotik)

-----
Для формирования списка команд в Телеграм-группе через бота BotFather необходимо выполнить действия с BotFather - 
вводим и отправляем команду: /setcommands выбираем нужного бота, выскочит подсказка:
~~~
    command1 - Description
    command2 - Another description
~~~
По сути это шаблон с указанием формата ввода команд, в котором каждая команда должна быть оформлена отдельной строкой. В каждой строке слева от дефиса находится команда в виде слова, которое будет отправлено в ТГ-группу при выборе этой команды. В каждой строке справа от дефиса обязательно должно присутствовать краткое описание команды. Необходимо обратить внимание на важные детали при формировании текстовых строк с командами:
- текст команды (слева от дефиса) может состоять ТОЛЬКО из цифр, маленьких латинских букв и знака подчёркивания (заглавные буквы, пробелы, спецсимволы и кириллица недопустимы).
- текст описания (справа от дефиса) может содержать любые символы. Текст обязательно должен быть.
- при добавлении новых команд, старые команды нужно вбивать вновь... Другими словами: все команды нужно вводить одним списком.

Вводится и отправляется команда по шаблону: 'имямикротик_имяскрипта - текст с описанием.'
Если всё сделано правильно, будет получен ответ: 'Success! Command list updated.'

Обратите внимание! При вводе списка предустановленных команд BotFather требует, чтобы слева от дефиса находилось только одно слово - сама команда, а для работы TLGRM необходимо, чтобы команда содержала в себе ID устройства и имя скрипта/функции/команды ROS разделённые пробелом. Для обхода этой нестыковки пришлось научить TLGRM считать тождественными пробелы (' ') и знаки подчёркивания ('_'). Теперь строка 'имямикротик_имяскрипта' для BotFather выглядит как одно слово, а для TLGRM выглядит как разные слова. Таким образом BotFather тянет за собой зависимость -> ID устройств и названия скриптов **ОБЯЗАНЫ** состоять только из маленьких латинских букв и цифр (заглавные буквы, пробелы, знаки подчёркивания, спецсимволы и кириллица недопустимы!!!).
После формирования списка предустановленных команд BotFather, нажав на кнопку "/" в своём чате с ботом можно видеть этот список, и при желании выбрать нужную команду на исполнение.

-----
Для корректного отображения скриптом 'username' отправителя, в настройках Телеграм должно быть заполнено поле "Имя пользователя", бот должен быть подключен к ГРУППЕ (групповому чату), а не к КАНАЛУ. Опытным путём выяснено, что предпочтителен групповой чат Телеграм с id БЕЗ префикса '-100', в таком чате сообщения от ГРУППЫ роутеров не теряются.

## Список литературы:
- https://forummikrotik.ru/viewtopic.php?p=89956#p89956
- https://forum.mikrotik.com/viewtopic.php?p=1012951#p1012951
- https://habr.com/ru/post/650563

**Используете скрипт - отметьте это звездочкой, Вам не сложно, а мне приятно!**
