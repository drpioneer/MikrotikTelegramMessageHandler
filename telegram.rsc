# TLGRM - combined notifications script & launch of commands (scripts & functions) via Telegram
# Script uses ideas by Sertik, Virtue, Pepelxl, Dimonw, Jotne, Alice Tails, Chupaka, drPioneer
# https://forummikrotik.ru/viewtopic.php?p=81945#p81945
# tested on ROS 6.49.5
# updated 2022/05/05

:do {
    :local botID    "botXXXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    :local myChatID "-XXXXXXXXX";
    :local broadCast false;
    :local launchScr true;
    :local launchFnc true;
    :local launchCmd true;

    # Function of searching comments for MAC-address
    # https://forummikrotik.ru/viewtopic.php?p=73994#p73994
    :local FindMacAddr do={
        :if ($1~"[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]") do={
            :foreach idx in=[/ip dhcp-server lease find disabled=no] do={
                :local mac [/ip dhcp-server lease get $idx mac-address];
                :if ($1~"$mac") do={:return ("$1 [$[/ip dhcp-server lease get $idx address]/$[/ip dhcp-server lease get $idx comment]].")};
            }
            :foreach idx in=[/interface bridge host find] do={
                :local mac [/interface bridge host get $idx mac-address];
                :if ($1~"$mac") do={:return ("$1 [$[/interface bridge host get $idx on-interface]].")};
            }
        }
        :return ($1);
    }

    # Function of converting CP1251 to UTF8
    # https://forummikrotik.ru/viewtopic.php?p=81457#p81457
    :local CP1251toUTF8 do={
        :local cp1251 [:toarray {
            "\20";"\01";"\02";"\03";"\04";"\05";"\06";"\07";"\08";"\09";"\0A";"\0B";"\0C";"\0D";"\0E";"\0F";\
            "\10";"\11";"\12";"\13";"\14";"\15";"\16";"\17";"\18";"\19";"\1A";"\1B";"\1C";"\1D";"\1E";"\1F";\
            "\21";"\22";"\23";"\24";"\25";"\26";"\27";"\28";"\29";"\2A";"\2B";"\2C";"\2D";"\2E";"\2F";"\3A";\
            "\3B";"\3C";"\3D";"\3E";"\3F";"\40";"\5B";"\5C";"\5D";"\5E";"\5F";"\60";"\7B";"\7C";"\7D";"\7E";\
            "\C0";"\C1";"\C2";"\C3";"\C4";"\C5";"\C6";"\C7";"\C8";"\C9";"\CA";"\CB";"\CC";"\CD";"\CE";"\CF";\
            "\D0";"\D1";"\D2";"\D3";"\D4";"\D5";"\D6";"\D7";"\D8";"\D9";"\DA";"\DB";"\DC";"\DD";"\DE";"\DF";\
            "\E0";"\E1";"\E2";"\E3";"\E4";"\E5";"\E6";"\E7";"\E8";"\E9";"\EA";"\EB";"\EC";"\ED";"\EE";"\EF";\
            "\F0";"\F1";"\F2";"\F3";"\F4";"\F5";"\F6";"\F7";"\F8";"\F9";"\FA";"\FB";"\FC";"\FD";"\FE";"\FF";\
            "\A8";"\B8";"\B9"}];
        :local utf8 [:toarray {
            "0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"000A";"0020";"0020";"000D";"0020";"0020";\
            "0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";\
            "0021";"0022";"0023";"0024";"0025";"0026";"0027";"0028";"0029";"002A";"002B";"002C";"002D";"002E";"002F";"003A";\
            "003B";"003C";"003D";"003E";"003F";"0040";"005B";"005C";"005D";"005E";"005F";"0060";"007B";"007C";"007D";"007E";\
            "D090";"D091";"D092";"D093";"D094";"D095";"D096";"D097";"D098";"D099";"D09A";"D09B";"D09C";"D09D";"D09E";"D09F";\
            "D0A0";"D0A1";"D0A2";"D0A3";"D0A4";"D0A5";"D0A6";"D0A7";"D0A8";"D0A9";"D0AA";"D0AB";"D0AC";"D0AD";"D0AE";"D0AF";\
            "D0B0";"D0B1";"D0B2";"D0B3";"D0B4";"D0B5";"D0B6";"D0B7";"D0B8";"D0B9";"D0BA";"D0BB";"D0BC";"D0BD";"D0BE";"D0BF";\
            "D180";"D181";"D182";"D183";"D184";"D185";"D186";"D187";"D188";"D189";"D18A";"D18B";"D18C";"D18D";"D18E";"D18F";\
            "D001";"D191";"2116"}];
        :local convStr ""; 
        :local code "";
        :for i from=0 to=([:len $1]-1) do={
            :local symb [:pick $1 $i ($i+1)]; 
            :local idx [:find $cp1251 $symb];
            :local key ($utf8->$idx);
            :if ([:len $key]!=0) do={
                :set $code ("%$[:pick ($key) 0 2]%$[:pick ($key) 2 4]");
                :if ([pick $code 0 3]="%00") do={:set $code ([:pick $code 3 6])};
            } else={:set code ($symb)}; 
            :set $convStr ($convStr.$code);
        }
        :return ($convStr);
    }

    # Telegram messenger response parsing function
    # https://habr.com/ru/post/482802/
    :local MsgParser do={
        :local variaMod ("\"".$2."\"");
        :if ([:len [:find $1 $variaMod -1]]=0) do={:return ("'unknown'")};
        :local startLoc ([:find $1 $variaMod -1]+[:len $variaMod]+1);
        :local commaLoc ([:find $1 "," $startLoc]);
        :local brakeLoc ([:find $1 "}" $startLoc]);
        :local endLoc $commaLoc;
        :local startSymbol [:pick $1 $startLoc];
        :if ($brakeLoc!=0 and ($commaLoc=0 or $brakeLoc<$commaLoc)) do={:set endLoc $brakeLoc};
        :if ($startSymbol="{") do={:set endLoc ($brakeLoc+1)};
        :if ($3=true) do={:set startLoc ($startLoc+1); :set endLoc ($endLoc-1)};
        :if ($endLoc<$startLoc) do={:set endLoc ($startLoc+1)};
        :return ([:pick $1 $startLoc $endLoc]);
    }
    
    # Time translation function to UNIX-time
    # https://forum.mikrotik.com/viewtopic.php?t=75555#p790745
    # Usage: $EpochTime [time input]
    # Get current time: put [$EpochTime]
    # Read log time in one of three format: "hh:mm:ss", "mmm/dd hh:mm:ss" or "mmm/dd/yyyy hh:mm:ss"
    :local EpochTime do={
        :local ds [/system clock get date];
        :local ts [/system clock get time];
        :if ([:len $1]>19) do={:set ds "$[:pick $1 0 11]"; :set ts [:pick $1 12 20]};
        :if ([:len $1]>8 && [:len $1]<20) do={:set ds "$[:pick $1 0 6]/$[:pick $ds 7 11]"; :set ts [:pick $1 7 15]};
        :local yesterday false;
        :if ([:len $1]=8) do={
            :if ([:totime $1]>ts) do={:set yesterday (true)};
            :set ts $1;
        }
        :local months;
        :if ((([:pick $ds 9 11]-1)/4)!=(([:pick $ds 9 11])/4)) do={
            :set months {"an"=0;"eb"=31;"ar"=60;"pr"=91;"ay"=121;"un"=152;"ul"=182;"ug"=213;"ep"=244;"ct"=274;"ov"=305;"ec"=335};
        } else={
            :set months {"an"=0;"eb"=31;"ar"=59;"pr"=90;"ay"=120;"un"=151;"ul"=181;"ug"=212;"ep"=243;"ct"=273;"ov"=304;"ec"=334};
        }
        :set ds (([:pick $ds 9 11]*365)+(([:pick $ds 9 11]-1)/4)+($months->[:pick $ds 1 3])+[:pick $ds 4 6]);
        :set ts (([:pick $ts 0 2]*3600)+([:pick $ts 3 5]*60)+[:pick $ts 6 8]);
        :if (yesterday) do={:set ds ($ds-1)};
        :return ($ds*86400+$ts+946684800-[/system clock get gmt-offset]);
    }

    # Time conversion function from UNIX-time
    # https://forummikrotik.ru/viewtopic.php?t=11636
    # usage: [$UnixTimeToFormat "timeStamp" "type"]
    # type: "unspecified" - month/dd/yyyy <only>    (Mikrotik sheduller format)
    #                   1 - yyyy/mm/dd hh:mm:ss
    #                   2 - dd:mm:yyyy hh:mm:ss
    #                   3 - dd month yyy hh mm ss
    #                   4 - yyyy month dd hh mm ss
    #                   5 - month/dd/yyyy-hh:mm:ss  (Mikrotik sheduller format)
    :local UnixTimeToFormat do={
        :local decodedLine "";
        :local timeStamp $1;
        :local timeS ($timeStamp%86400);
        :local timeH ($timeS/3600);
        :local timeM ($timeS%3600 /60);
        :set  $timeS ($timeS-$timeH*3600-$timeM*60);
        :local dateD ($timeStamp/86400);
        :local dateM 2;
        :local dateY 1970;
        :local leap false;
        :while (($dateD/365)>0) do={
            :set $dateD ($dateD-365);
            :set $dateY ($dateY+1);
            :set $dateM ($dateM+1);
            :if ($dateM=4) do={
                :set $dateM 0;
                :if (($dateY%400=0) or ($dateY%100!=0)) do={:set $leap true; :set $dateD ($dateD-1)};
            } else={:set $leap false};
        }
        :local months [:toarray (0,31,28,31,30,31,30,31,31,30,31,30,31)];
        :if (leap) do={:set $dateD ($dateD+1); :set ($months->2) 29};
        :do {
            :for i from=1 to=12 do={
                :if (($months->$i)>$dateD) do={
                    :set $dateM $i;
                    :set $dateD ($dateD+1);
                    break;
                } else={:set $dateD ($dateD-($months->$i))};
            }
        } on-error={};
        :local tmod;
        :if ([:len $2]!=0) do={:set $tmod $2} else={:set $tmod (:nothing)};
        :local sl "/";
        :local mstr {"jan";"feb";"mar";"apr";"may";"jun";"jul";"aug";"sep";"oct";"nov";"dec"};
        :local strY [:tostr $dateY];
        :local strN;
        :local strD;
        :local strH;
        :local strM;
        :local strS;
        :if ($dateM>9) do={:set $strN [:tostr $dateM]} else={:set $strN ("0".[:tostr $dateM])};
        :if ($dateD>9) do={:set $strD [:tostr $dateD]} else={:set $strD ("0".[:tostr $dateD])};
        :if ($timeH>9) do={:set $strH [:tostr $timeH]} else={:set $strH ("0".[:tostr $timeH])};
        :if ($timeM>9) do={:set $strM [:tostr $timeM]} else={:set $strM ("0".[:tostr $timeM])};
        :if ($timeS>9) do={:set $strS [:tostr $timeS]} else={:set $strS ("0".[:tostr $timeS])};
        :do {
            :if ([:len $tmod]=0) do={:local mt ($mstr->($dateM-1)); :set $decodedLine ("$mt/"."$strD/"."$strY"); break};
            :if ($tmod=1) do={:set $decodedLine "$strY$sl$strN$sl$strD $strH:$strM:$strS"; break};
            :if ($tmod=2) do={:set $decodedLine "$strD$sl$strN$sl$strY $strH:$strM:$strS"; break};
            :if ($tmod=3) do={:set $decodedLine ("$strD ".($mstr->($dateM-1))." $strY $strH:$strM:$strS"); break};
            :if ($tmod=4) do={:set $decodedLine ("$strY ".($mstr->($dateM-1))." $strD $strH:$strM:$strS"); break};
            :if ($tmod=5) do={:local m ($mstr->($dateM-1)); :set $decodedLine ("$m/"."$strD/"."$strY"."-$strH:$strM:$strS"); break};
        } on-error={};
        :return ($decodedLine);
    }

    # Main body of the script
    :global timeAct;
    :global timeLog;
    :local  nameID [/system identity get name];
    :local  timeOf [/system clock get gmt-offset];
    :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Start of TLGRM-script on '$nameID' router.");
    :if ([:len $timeAct]>0) do={:put ("$[$UnixTimeToFormat ($timeAct+$timeOf) 1] - Time when the last command was launched.")};
    :if ([:len $timeLog]>0) do={:put ("$[$UnixTimeToFormat ($timeLog+$timeOf) 1] - Time when the log entries were last sent.")};

    # Part of the script body to launch via Telegram
    # https://forummikrotik.ru/viewtopic.php?p=78085
    :local timeStmp [$EpochTime];
    :local urlString "https://api.telegram.org/$botID/getUpdates\?offset=-1&limit=1&allowed_updates=message";
    :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - *** Stage of launch scripts, function & commands via Telegram:");
    :if ([:len $timeAct]=0) do={
        :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Time of the last launch of the command was not found.");
        :set timeAct $timeStmp;
    } else={
        :local httpResp [/tool fetch url=$urlString as-value output=user];
        :local content ($httpResp->"data");
        :if ([:len $content]>30) do={
            :local msgTxt [$MsgParser $content "text" true];
            :set   msgTxt ([:pick $msgTxt ([:find $msgTxt "/" -1]+1) [:len $msgTxt]]);
            :local newStr "";
            :local change "";
            :for i from=0 to=([:len $msgTxt]-1) do={
                :local symb [:pick $msgTxt $i ($i+1)]; 
                :if ($symb="_") do={:set change (" ")} else={:set change ($symb)}; 
                :set $newStr ($newStr.$change);
            }
            :set msgTxt $newStr;
            :local msgAddr "";
            :if ($broadCast) do={:set $msgAddr $nameID} else={
                :set msgAddr ([:pick $msgTxt 0 [:find $msgTxt " " -1]]);
                :if ([:len [:find $msgTxt " "]]=0) do={:set msgAddr ("$msgTxt ")};
                :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Recipient of the Telegram message: '$msgAddr'");
                :set msgTxt ([:pick $msgTxt ([:find $msgTxt $msgAddr -1]+[:len $msgAddr]+1) [:len $msgTxt]]);
            }
            :if ($msgAddr=$nameID or $msgAddr="forall") do={
                :local chatID [$MsgParser [$MsgParser $content "chat"] "id"];
                :local userNm [$MsgParser $content "username"];
                :set timeStmp [$MsgParser $content "date"];
                :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Sender of the Telegram message: $userNm");
                :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Command to execute: '$msgTxt'");
                :local restline [];
                :if ([:len [:find $msgTxt " "]]!=0) do={
                    :set restline [:pick $msgTxt ([:find $msgTxt " "]+1) [:len $msgTxt]];
                    :set msgTxt [:pick $msgTxt 0 [:find $msgTxt " "]];
                }
                :if ($chatID=$myChatID && $timeAct<$timeStmp) do={
                    :set timeAct $timeStmp;
                    :if ([/system script environment find name=$msgTxt]!="" && $launchFnc=true) do={   
                        :if (([/system script environment get [/system script environment find name=$msgTxt] value]="(code)") \
                            or ([:len [:find [/system script environment get [/system script environment find name=$msgTxt] value] "(eval"]]>0)) do={
                            :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Telegram user $userNm launches function '$msgTxt'.");
                            :log warning ("Telegram user $userNm launches function '$msgTxt'.");
                            [:parse ":global $msgTxt; [\$$msgTxt $restline]"];
                        } else={
                            :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - '$msgTxt' is a global variable and not a function - no execute.");
                            :log warning ("'$msgTxt' is a global variable and not a function - no execute.");
                        }
                    }
                    :if ([/system script find name=$msgTxt]!="" && $launchScr=true) do={
                        :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Telegram user $userNm activates script '$msgTxt'.");
                        :log warning ("Telegram user $userNm activates script '$msgTxt'.");
                        [[:parse "[:parse [/system script get $msgTxt source]] $restline"]];
                    }
                    :if ([/system script find name=$msgTxt]="" && [/system script environment find name=$msgTxt]="" && $launchCmd=true) do={
                        :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Telegram user $userNm is trying to execute command '$msgTxt'.");
                        :log warning ("Telegram user $userNm is trying to execute command '$msgTxt'.");
                        :do {[:parse "/$msgTxt $restline"]} on-error={};
                    }
                } else={:put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Wrong time to launch.")};
            } else={:put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - No command found for this device.")};
        } else={:put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Completion of response from Telegram.")};
    }

    # Part of the script body for notifications in Telegram
    # https://www.reddit.com/r/mikrotik/comments/onusoj/sending_log_alerts_to_telegram/
    :local outMsg "";
    :local logGet [:toarray [/log find ($topics~"warning" or $topics~"error" or $topics~"critical" or $topics~"caps" or $topics~"wireless" or $message~"logged in")]];
    :local logCnt [:len $logGet];
    :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - *** Stage of sending notifications to Telegram:");
    :if ([:len $timeLog]=0) do={ 
        :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Time of the last log entry was not found.");
        :set outMsg (">$[/system clock get time] Telegram notification started.");
    }
    :if ($logCnt>0) do={
        :local lastTime [$EpochTime [/log get [:pick $logGet ($logCnt-1)] time]];
        :local index 0;
        :local tempTim "";
        :local tempMsg "";
        :local tempTpc "";
        :local unixTim "";
        :do {
            :set index ($index+1); 
            :set tempTim [/log get [:pick $logGet ($logCnt-$index)] time];
            :set tempTpc [/log get [:pick $logGet ($logCnt-$index)] topics];
            :set tempMsg [/log get [:pick $logGet ($logCnt-$index)] message];
            :set tempMsg (">$tempTim $tempMsg");
            :local findMacMsg ([$FindMacAddr $tempMsg]);
            :set unixTim [$EpochTime $tempTim];
            :if (($unixTim>$timeLog) && (!(($tempTpc~"caps" or $tempTpc~"wireless" or $tempTpc~"dhcp") && ($tempMsg!=$findMacMsg)))) do={
                :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Found log entry: $findMacMsg");
                :set outMsg ($findMacMsg."\n".$outMsg);
            }
        } while=(($unixTim>$timeLog) && ($index<$logCnt));
        :if (([:len $timeLog]<1) or (([:len $timeLog]>0) && ($timeLog!=$lastTime) && ([:len $outMsg]>8))) do={
            :set timeLog $lastTime;
            :if ([:len $outMsg]>4096) do={:set outMsg ([:pick $outMsg 0 4096])};
            :set outMsg [$CP1251toUTF8 $outMsg];
            :local urlString ("https://api.telegram.org/$botID/sendmessage\?chat_id=$myChatID&text=$nameID:%0A$outMsg");
            :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Generated string for Telegram:\r\n".$urlString);
            /tool fetch url=$urlString as-value output=user;
        } else={:put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - There are no log entries to send.")};
    } else={:put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - Necessary log entries were not found.")};
    :put ("$[$UnixTimeToFormat ([$EpochTime]+$timeOf) 1] - End of TLGRM-script on '$nameID' router.");
} on-error={ 
    :put ("Script error: something didn't work when sending a request to Telegram.");
    :put ("*** First, check the correctness of the values of the variables botID & myChatID. ***"); 
}
