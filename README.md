# TLGRM - скрипт оповещения в Телеграм и удалённого запуска функций, скриптов и команд RouterOS.

Скрипт предназначен для отправки записей журналов устройств Mikrotik в заданную Telegram-группу и удалённого запуска функций, скриптов и команд RouterOS. Работосопособность скрипта проверялась на актуальных версиях RouterOS 6.49.++ и 7.14.++ . 
В скрипте использованы идеи и части кода разных авторов, найденные на просторах интернета.
Код скрипта содержит в себе всё необходимое для работы, не имеет зависимостей от сторонних функций и скриптов, но имеет ограничения на используемые символы в ID устройства, вытекающие из требований BotFather на список предустановленных команд (см. далее в тексте).
Для работы, скрипт необходимо добавить в System/Scripts и настроить запуск в System/Sheduler с необходимым периодом, например 1 мин.

Во время работы скрипт взаимодействует с заданной Телеграм-группой и при этом:
- реагирует на принятые команды из сообщений группы
- транслирует в группу потенциально интересные записи журнала устройства

## Особенности работы скрипта:
- поддерживается отправка текстовых сообщений с кириллическими символами (CP1251)
- отправляемые текстовые сообщения обрезаются до 4096 байтов
- скрипт обрабатывает только ПОСЛЕДНЕЕ сообщение в ТГ-группе, по этой причине нет смысла отправлять несколько команд сразу, выполнится только последняя
- нарушение работы интернет-канала не влияет на работу скрипта, неотправленные сообщения будут отосланы после восстановления связи
- контроль работы скрипта доступен через терминал устройства: /system script run tlgrm (где 'tlgrm' - имя скрипта)
- поддерживается индивидуальная и групповая адресация команд
- в угоду корректной работы с некоторыми сервисами Телеграм, id устройства должно содержать только цифры и маленькие латинские буквы
- при отправке только одной записи журнала, эта запись отправляется вместе с id роутера без разделителя в виде символа переноса. Такой подход позволяет читать сообщение на мобильном устройстве в шторке уведомлений не разблокируя устройство
- трансляция в Телеграм сообщений о подключении/отключении беспроводных клиентов производится скриптом только в случаях, когда для МАС-адреса из строки журнала:
    - отсутствует соответствующий IP-адрес в списке DHCP/Leases
    - назначен динамический IP-адрес в списке DHCP/Leases
    - назначен статический IP-адрес в списке DHCP/Leases и при этом комментарий к нему отсутствует

Отправка команды всем или одному конкретному роутеру, находящемуся в ТГ-группе, подразумевает отправку подготовленного специальным образом сообщения, 
при этом скрипт должен быть запущен на всех роутерах, которым может быть адресовано сообщение. Для отправки команды необходимо сформировать сообщение в виде текстовой строки специального формата: 
 - начало сообщения обозначается символом "/"
 - затем указывается имя устройства, которому адресовано сообщение (соответствует /system identity устройства). Для отправки всем роутерам в Телеграм-группе в качестве адресата указать: forall. Для корректной работы имя устройства должно содержать ТОЛЬКО цифры и маленькие латинские буквы (!!!).
 - далее через символ подчеркивания или пробел указывается непосредственно команда. В качестве команды могут выступать: имя глобальной функции, имя скрипта или команда RouterOS.

Примеры строк с командами:
~~~ 
  /forall log warning [/system resource get uptime]
  /mikrotik1_wol
  /mikrotik system reboot
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
Для формирования списка команд в Телеграм-группе через бота BotFather необходимо выполнить последовательность действий с BotFather: 
вводим и отправляем команду: /setcommands выбираем нужного бота, выскочит подсказка:
~~~
    command1 - Description
    command2 - Another description
~~~
По сути это шаблон с указанием формата ввода команд, в котором каждая команда должна быть оформлена отдельной строкой. В каждой строке слева от дефиса находится команда в виде слова, которое будет отправлено в ТГ-группу при выборе этой команды. В каждой строке справа от дефиса обязательно должно присутствовать краткое описание команды. Также необходимо обратить внимание на важные детали при формировании текстовых строк с командами:
- текст команды (слева от дефиса) может состоять ТОЛЬКО из цифр, маленьких латинских букв и знака подчёркивания (заглавные буквы, пробелы, спецсимволы и кириллица недопустимы).
- текст описания (справа от дефиса) может содержать любые символы. Текст обязательно должен быть.
- при добавлении новых команд, старые команды нужно вбивать вновь... Другими словами: все команды нужно вводить одним списком.

Вводим и отправляем команду по шаблону: 'имямикротик_имяскрипта - текст с описанием.'
Если всё сделано правильно, получим ответ: 'Success! Command list updated.'

Обратите внимание! При вводе списка предустановленных команд BotFather требует, чтобы слева от дефиса находилось только одно слово - сама команда, а для работы TLGRM необходимо, чтобы команда содержала в себе ID устройства и имя скрипта/функции/команды ROS разделённые пробелом. Для обхода этой нестыковки пришлось научить TLGRM считать тождественными пробелы (' ') и знаки подчёркивания ('_'). В этом случае строка 'имямикротик_имяскрипта' для BotFather выглядит как одно слово, а для TLGRM выглядит как разные слова. Таким образом BotFather тянет за собой зависимость -> ID устройств и названия скриптов должны состоять только из цифр и маленьких латинских букв (заглавные буквы, пробелы, знаки подчёркивания, спецсимволы и кириллица недопустимы!!!).
После формирования списка предустановленных команд BotFather, нажав на кнопку "/" в своём чате с ботом можно видеть этот список, и при желании выбрать нужную команду на исполнение.

-----
Для корректного отображения скриптом 'username' отправителя, в настройках Телеграм должно быть заполнено поле "Имя пользователя", бот должен быть подключен к ГРУППЕ (групповому чату), а не к КАНАЛУ. Опытным путём выяснено, что предпочтителен групповой чат Телеграм с id БЕЗ префикса '-100', в таком чате сообщения от ГРУППЫ роутеров не теряются.

## Список литературы:
- https://forummikrotik.ru/viewtopic.php?p=89956#p89956
- https://forum.mikrotik.com/viewtopic.php?p=1012951#p1012951
- https://habr.com/ru/post/650563
