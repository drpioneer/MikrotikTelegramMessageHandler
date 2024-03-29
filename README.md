# TLGRM - скрипт оповещения в Телеграм и удалённого запуска функций, скриптов и команд RouterOS.

В скрипте использованы идеи и части кода разных авторов, найденные на просторах интернета.
Код скрипта содержит в себе всё необходимое для работы и не имеет зависимостей от сторонних функций и скриптов.
Для работы, скрипт необходимо добавить в System/Scripts и настроить запуск в System/Sheduler с необходимым периодом, например 1 мин.
Работосопособность скрипта проверялась только на актуальных версиях RouterOS: 6.49+ и 7.10+ .

Во время работы скрипт взаимодействует с заданной Телеграм-группой и при этом:
- реагирует на принятые команды из сообщений группы
- транслирует потенциально интересные записи журнала устройства в группу 

## Особенности работы скрипта:
- поддерживается отправка текстовых сообщений с кириллическими символами (CP1251)
- отправляемые текстовые сообщения обрезаются до 4096 байтов
- скрипт обрабатывает только ПОСЛЕДНЕЕ сообщение в ТГ-группе, по этой причине нет смысла отправлять несколько команд сразу, выполнится только последняя.
- нарушение работы интернет-канала не влияет на работоспособность скрипта, накопившиеся сообщения будут отосланы после восстановления связи.
- ход работы скрипта доступен для контроля через терминал устройства: /system script run tlgrm (где 'tlgrm' - имя скрипта)
- поддерживается индивидуальная и групповая адресация команд
- регистр символов id устройства игнорируется
- при отправке одной записи журнала, эта запись отправляется вместе с id роутера без разделителя в виде символа переноса. Такой подход позволяет читать сообщение на мобильном устройстве в шторке уведомлений не разблокируя устройство
- трансляция в Телеграм сообщений о подключении/отключении беспроводных клиентов производится скриптом только в случаях, когда для МАС-адреса из строки журнала:
    - отсутствует соответствующий IP-адрес в списке DHCP/Leases
    - назначен динамический IP-адрес в списке DHCP/Leases
    - назначен статический IP-адрес в списке DHCP/Leases и при этом комментарий к нему отсутствует

Отправка команды всем или одному конкретному роутеру, находящемуся в ТГ-группе, подразумевает отправку подготовленного специальным образом сообщения, 
при этом скрипт должен работать на всех роутерах, которым может быть адресовано сообщение. Для отправки команды конкретному роутеру в ТГ-группе необходимо сформировать текстовое сообщение специальным образом: начало сообщения обозначается символом "/" с указанием имени роутера, которое должно соответствовать
/system identity и не должно содержать пробелов, далее через пробел или символ '_' (подчеркивание) указывается команда. Для отправки команды всем
роутерам в ТГ-группе, вместо имени необходимо указать 'forall'. 
В качестве команды могут выступать: имя глобальной функции, имя скрипта или команда RouterOS, например:
~~~ 
  /forall log warning [/system identity get name]
  /mikrotik1 wol
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
- **userInfo**,  где true = разрешение трансляции в ТГ-чат сообщений, сформированных по пользовательским условиям; false = запрет трансляции пользовательских сообщений

Минимальная настройка скрипта сводится к указанию идентификаторов бота и группы: [botID и myChatID](https://1spla.ru/blog/telegram_bot_for_mikrotik)

-----
Для формирования списка команд в Телеграм-группе через бота BotFather необходимо выполнить последовательность действий с BotFather: 
вводим и отправляем команду: /setcommands выбираем нужного бота, выскочит подсказка:
~~~
    command1 - Description
    command2 - Another description
~~~
По сути это шаблон с указанием формата ввода команд, в котором каждая команда должна быть оформлена отдельной строкой, в каждой строке слева от дефиса должен 
находиться текст с командой. Этот текст в дальнейшем и будет отправляться при выборе команды. В каждой строке справа от дефиса пишется краткое описание команды. 
Оно нужно для того, чтобы не держать в голове все команды. Описание напомнит, что это за команда и что она делает. Следует обратить внимание на важные детали 
при формировании текстовых строк с командами:
- текст команды (слева от дефиса) может состоять ТОЛЬКО из цифр, маленьких латинских букв и знака подчёркивания (заглавные буквы, пробелы, спецсимволы и кириллица недопустимы).
- текст описания (справа от дефиса) может содержать любые символы. Текст обязательно должен быть.
- при добавлении новых команд, старые команды нужно вбивать вновь... Другими словами: все команды нужно вводить одним списком.

Вводим и отправляем команду по шаблону: имямикротик_имяскрипта - текст с описанием.
Если всё сделано правильно, получим ответ: 'Success! Command list updated.'
Обратите внимание! В "команду" мы на самом деле запихиваем 'имямикротик' и 'имяскрипта' через символ подчёркивания. 
Это делается чтобы BotFather не ругался и проглотил эту "команду", в которой на самом деле зашифровано имя роутера с названием скрипта, 
которые в свою очередь должны быть обработаны TLGRM. А т.к. для наших целей пробелы нужны как минимум для отделения ID маршрутизатора от команды, 
пришлось заниматься самообманом: отныне скрипт считает пробелы (' ') и знаки подчёркивания ('_') тождественными. Таким образом BotFather тянет за собой 
зависимость -> ID роутеров и названия скриптов могут состоять только из цифр и маленьких латинских букв (заглавные буквы, пробелы, знаки подчёркивания, 
спецсимволы и кириллица недопустимы!!!). Теперь, нажав на кнопку "/" в своём чате с ботом, можно посмотреть, какие команды (скрипты) и на каких устройствах 
нам доступны, а при желании можно выбрать нужную команду и отправить её на исполнение.

-----
Для корректного отображения скриптом 'username' отправителя, в настройках Телеграм должно быть заполнено поле "Имя пользователя", бот должен быть подключен к ГРУППЕ (групповому чату), а не к КАНАЛУ. Опытным путём выяснено, что предпочтителен групповой чат Телеграм с id БЕЗ префикса '-100', в таком чате сообщения от ГРУППЫ роутеров не теряются.

## Список литературы:
- https://forummikrotik.ru/viewtopic.php?p=89956#p89956
- https://forum.mikrotik.com/viewtopic.php?p=1012951#p1012951
- https://habr.com/ru/post/650563
