# Combined notification script and script launch via Telegram  by drPioneer
# https://forummikrotik.ru/viewtopic.php?p=81945#p81945
# tested on ROS 6.49
# updated 2022/01/01

:do {
    :local botID    "botXXXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    :local myChatID "-XXXXXXXXX";

    # Function of searching comments for MAC-address by Virtue
    # https://forummikrotik.ru/viewtopic.php?p=73994#p73994
    :local FindMacAddr do={
        :if ($1 ~"[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]") do={
            :foreach idx in=[ /ip dhcp-server lease find dynamic=no disabled=no; ] do={
                :local mac  [ /ip dhcp-server lease get $idx mac-address; ];
                :if ($1 ~"$mac") do={ 
                    :return ("$1 [$[ /ip dhcp-server lease get $idx address; ]/\
                        $[ /ip dhcp-server lease get $idx comment; ]]."); 
                } 
            }
            :foreach idx in=[ /interface bridge host find; ] do={
                :local mac  [ /interface bridge host get $idx mac-address; ];
                :if ($1 ~"$mac") do={ :return ("$1 [$[ /interface bridge host get $idx on-interface; ]]."); }
            }
        }
        :return ($1);
    }

    # Function of converting CP1251 to UTF8 by Sertik
    # https://forummikrotik.ru/viewtopic.php?p=81457#p81457
    :local CP1251toUTF8 do={
        :local cp1251 [:toarray {"\20";"\01";"\02";"\03";"\04";"\05";"\06";"\07";"\08";"\09";"\0A";"\0B";"\0C";"\0D";"\0E";"\0F"; \
                                 "\10";"\11";"\12";"\13";"\14";"\15";"\16";"\17";"\18";"\19";"\1A";"\1B";"\1C";"\1D";"\1E";"\1F"; \
                                 "\21";"\22";"\23";"\24";"\25";"\26";"\27";"\28";"\29";"\2A";"\2B";"\2C";"\2D";"\2E";"\2F";"\3A"; \
                                 "\3B";"\3C";"\3D";"\3E";"\3F";"\40";"\5B";"\5C";"\5D";"\5E";"\5F";"\60";"\7B";"\7C";"\7D";"\7E"; \
                                 "\C0";"\C1";"\C2";"\C3";"\C4";"\C5";"\C7";"\C7";"\C8";"\C9";"\CA";"\CB";"\CC";"\CD";"\CE";"\CF"; \
                                 "\D0";"\D1";"\D2";"\D3";"\D4";"\D5";"\D6";"\D7";"\D8";"\D9";"\DA";"\DB";"\DC";"\DD";"\DE";"\DF"; \
                                 "\E0";"\E1";"\E2";"\E3";"\E4";"\E5";"\E6";"\E7";"\E8";"\E9";"\EA";"\EB";"\EC";"\ED";"\EE";"\EF"; \
                                 "\F0";"\F1";"\F2";"\F3";"\F4";"\F5";"\F6";"\F7";"\F8";"\F9";"\FA";"\FB";"\FC";"\FD";"\FE";"\FF"; \
                                 "\A8";"\B8";"\B9"}];
        :local utf8   [:toarray {"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"000A";"0020";"0020";"000D";"0020";"0020"; \
                                 "0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020"; \
                                 "0021";"0022";"0023";"0024";"0025";"0026";"0027";"0028";"0029";"002A";"002B";"002C";"002D";"002E";"002F";"003A"; \
                                 "003B";"003C";"003D";"003E";"003F";"0040";"005B";"005C";"005D";"005E";"005F";"0060";"007B";"007C";"007D";"007E"; \
                                 "D090";"D091";"D092";"D093";"D094";"D095";"D096";"D097";"D098";"D099";"D09A";"D09B";"D09C";"D09D";"D09E";"D09F"; \
                                 "D0A0";"D0A1";"D0A2";"D0A3";"D0A4";"D0A5";"D0A6";"D0A7";"D0A8";"D0A9";"D0AA";"D0AB";"D0AC";"D0AD";"D0AE";"D0AF"; \
                                 "D0B0";"D0B1";"D0B2";"D0B3";"D0B4";"D0B5";"D0B6";"D0B7";"D0B8";"D0B9";"D0BA";"D0BB";"D0BC";"D0BD";"D0BE";"D0BF"; \
                                 "D180";"D181";"D182";"D183";"D184";"D185";"D186";"D187";"D188";"D189";"D18A";"D18B";"D18C";"D18D";"D18E";"D18F"; \
                                 "D001";"D191";"2116"}];
        :local convStr ""; 
        :local code    "";
        :for i from=0 to=([:len $1]-1) do={
            :local symb [:pick $1 $i ($i+1)]; 
            :local idx  [:find $cp1251 $symb];
            :local key  ($utf8->$idx);
            :if ([:len $key] != 0) do={
                :set $code ("%$[:pick ($key) 0 2]%$[:pick ($key) 2 4]");
                :if ([pick $code 0 3] = "%00") do={ :set $code ([:pick $code 3 6]); }
            } else={ :set code ($symb); }; 
            :set $convStr ($convStr.$code);
        }
        :return ($convStr);
    }

    # Telegram messenger response parsing function by Dimonw
    # https://habr.com/ru/post/482802/
    :local MsgParser do={
        :local variaMod ("\"".$2);
        :local startLoc ([:find $1 $variaMod -1] + [:len $variaMod] + 2);
        :local commaLoc ([:find $1 "," $startLoc]);
        :local brakeLoc ([:find $1 "}" $startLoc]);
        :local endLoc $commaLoc;
        :local startSymbol [:pick $1 $startLoc]; 
        :if ($brakeLoc != 0 and ($commaLoc = 0 or $brakeLoc < $commaLoc)) do={ :set endLoc $brakeLoc; };
        :if ($startSymbol = "{") do={ :set endLoc ($brakeLoc + 1); };
        :if ($3 = true) do={
            :set startLoc ($startLoc + 1);
            :set endLoc   ($endLoc   - 1);
        }
        :if ($endLoc < $startLoc) do={ :set endLoc ($startLoc + 1); };
        :return ([:pick $1 $startLoc $endLoc]);
    }
    
    # Time translation function to UNIX-time by Jotne
    # https://forum.mikrotik.com/viewtopic.php?t=75555#p790745
    :local EpochTime do={
        :local ds [ /system clock get date; ];
        :local ts [ /system clock get time; ];
        :if ([:len $1] > 19) do={
            :set ds "$[:pick $1 0 11]";
            :set ts [:pick $1 12 20];
        }
        :if ([:len $1] > 8 && [:len $1] < 20) do={
            :set ds "$[:pick $1 0 6]/$[:pick $ds 7 11]";
            :set ts [:pick $1 7 15];
        }
        :local yesterday false;
        :if ([:len $1] = 8) do={
            :if ([:totime $1] > ts) do={ :set yesterday (true); }
            :set ts $1;
        }
        :local months;
        :if ((([:pick $ds 9 11]-1)/4) != (([:pick $ds 9 11])/4)) do={
            :set months {"an"=0;"eb"=31;"ar"=60;"pr"=91;"ay"=121;"un"=152;"ul"=182;"ug"=213;"ep"=244;"ct"=274;"ov"=305;"ec"=335};
        } else={
            :set months {"an"=0;"eb"=31;"ar"=59;"pr"=90;"ay"=120;"un"=151;"ul"=181;"ug"=212;"ep"=243;"ct"=273;"ov"=304;"ec"=334};
        }
        :set ds (([:pick $ds 9 11]*365)+(([:pick $ds 9 11]-1)/4)+($months->[:pick $ds 1 3])+[:pick $ds 4 6]);
        :set ts (([:pick $ts 0 2]*3600)+([:pick $ts 3 5]*60)+[:pick $ts 6 8]);
        :if (yesterday) do={ :set ds ($ds-1); }
        :return ($ds*86400 + $ts + 946684800 - [ /system clock get gmt-offset; ]);
    }

    # Main body of the script
    :global timeAct;
    :global timeLog;
    :local  nameID [ /system identity get name; ];
    :put ("$[$EpochTime] sec - current Unix-time of $nameID router.");
    if ([:len $timeAct] > 0) do={ :put ("$timeAct sec - time of checking the last script run."); }
    if ([:len $timeLog] > 0) do={ :put ("$timeLog sec - time of the last log check."); }

    # Part of the script body for running scripts via Telegram by drPioneer
    # https://forummikrotik.ru/viewtopic.php?p=78085
    :local  timeStamp [$EpochTime];
    :local  urlString "https://api.telegram.org/$botID/getUpdates\?offset=-1&limit=1&allowed_updates=message";
    :put ("... Stage of running scripts via Telegram:");
    :if ([:len $timeAct] = 0) do={
        :put ("Time of the last script activation was not found.");
        :set timeAct $timeStamp;
    } else={
        :local httpResp [ /tool fetch url=$urlString as-value output=user; ];
        :local content ($httpResp->"data");
        :if ([:len $content] > 30) do={
            :local msgTxt   [$MsgParser $content "text" true];
            :set   msgTxt  ([:pick $msgTxt ([:find $msgTxt "/"] + 1) ([:len $msgTxt])]);
            :local chat     [$MsgParser $content "chat"];
            :local chatId   [$MsgParser $chat    "id"];
            :local userName [$MsgParser $content "username"];
            :set  timeStamp [$MsgParser $content "date"];
            :if (($chatId = $myChatID) && ($timeAct < $timeStamp) && ([ /system script find name=$msgTxt; ] != "")) do={ 
                :set timeAct ($timeStamp);
                :put ("$timeStamp sec - activated script '$msgTxt' from user $userName.");
                :log warning ("Telegram user $userName activated script '$msgTxt' in $timeStamp sec.");                 
                /system script run $msgTxt;
            } else={ :put ("Nothing to activated."); }
        } else={ :put ("Completion of response from Telegram."); }
    }

    # Part of the script body for notifications in Telegram by Alice Tails
    # https://www.reddit.com/r/mikrotik/comments/onusoj/sending_log_alerts_to_telegram/
    :local outMsg "";
    :local logGet [ :toarray [ /log find ($topics ~"warning" || $topics ~"error" || $topics ~"critical" || $topics ~"caps" \
    || $topics ~"wireless" || $message ~"logged in"); ]];
    :local logCnt [ :len $logGet ];
    :put ("... Stage of sending notifications to Telegram:");
    :if ([:len $timeLog] = 0) do={ 
        :put ("Time of the last log entry was not found.");
        :set outMsg (">$[ /system clock get time; ] Telegram notification started.");
    }
    :if ($logCnt > 0) do={
        :local lastTime [$EpochTime [ /log get [:pick $logGet ($logCnt-1)] time; ]];
        :local index 0;
        :local tempTime;
        :local tempMessage;
        :local tempTopic;
        :local unixTime;
        :do {
            :set index        ($index + 1); 
            :set tempTime     [ /log get [:pick $logGet ($logCnt - $index)]    time; ];
            :set tempTopic    [ /log get [:pick $logGet ($logCnt - $index)]  topics; ];
            :set tempMessage  [ /log get [:pick $logGet ($logCnt - $index)] message; ];
            :set tempMessage  (">".$tempTime." ".$tempMessage);
            :local findMacMsg ([$FindMacAddr $tempMessage]);
            :set unixTime [$EpochTime $tempTime];
            :if (($unixTime > $timeLog) && (!(($tempTopic ~"caps" || $tempTopic ~"wireless" || $tempTopic ~"dhcp") \
            && ($tempMessage != $findMacMsg)))) do={
                :put $findMacMsg;
                :set outMsg ($findMacMsg."\n".$outMsg);
            }
        } while=(($unixTime > $timeLog) && ($index < $logCnt));
        :if (([:len $timeLog] < 1) || (([:len $timeLog] > 0) && ($timeLog != $lastTime) && ([:len $outMsg] > 8) )) do={
            :set timeLog $lastTime;
            if ([:len $outMsg] > 4096) do={ :set outMsg ([:pick $outMsg 0 4096]); }
            :set outMsg [$CP1251toUTF8 $outMsg];
            :local urlString ("https://api.telegram.org/$botID/sendmessage\?chat_id=$myChatID&text=$nameID:%0A$outMsg");
            :put ("Generated string for Telegram:\r\n".$urlString);
            /tool fetch url=$urlString as-value output=user;
        } else={ :put ("Nothing to send."); }
    } else={ :put ("Necessary log entries were not found."); }
} on-error={ :put ("Script error: something went wrong when sending a request to Telegram."); }

