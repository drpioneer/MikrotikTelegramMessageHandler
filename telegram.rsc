# TLGRM - combined notifications script & launch of commands (scripts & functions) via Telegram
# Script uses ideas by Sertik, Virtue, Dimonw, -13-, Mk51, Alice Tails, Chupaka, rextended, drPioneer
# https://forummikrotik.ru/viewtopic.php?p=89956#p89956
# https://github.com/drpioneer/MikrotikTelegramMessageHandler
# tested on ROS 6.49.8
# updated 2023/07/14

:global scriptTlgrm;                                                                    # flag of the running script: false=in progress, true=idle
:do {
    :local botID    "botXXXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
    :local myChatID "-XXXXXXXXX";
    :local broadCast false;                                                             # non-addressed reception mode
    :local launchScr true;                                                              # permission to execute scripts
    :local launchFnc true;                                                              # permission to perform functions
    :local launchCmd true;                                                              # permission to execute commands
    :local userInfo false;                                                              # fragment of code for user information output
    :local emo {
        "phone"="%F0%9F%93%B1";"store"="%F0%9F%8F%AA";"envelope"="%E2%9C%89";
        "smile"="%F0%9F%98%8E";"bell"="%F0%9F%94%94";"memo"="%F0%9F%93%9D"};            # emoji list: https://apps.timwhitlock.info/emoji/tables/unicode
    :global timeAct;                                                                    # time when the last command was executed
    :global timeLog;                                                                    # time when the log entries were last sent

    # --------------------------------------------------------------------------------- # MAC address search function
    :local FindMAC do={                                                                 # https://forummikrotik.ru/viewtopic.php?p=73994#p73994
        :if (([:typeof $1]!="str") or ([:len $1]=0)) do={:return ""}
        :if ($1~"[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]") do={
            :foreach id in=[/ip dhcp-server lease find disabled=no] do={
                :local mac [/ip dhcp-server lease get $id mac-address];
                :if ($1~$mac) do={:return $mac}
            }
        }
        :return "";
    }

    # --------------------------------------------------------------------------------- # function of converting CP1251 to UTF8 in URN-standart
    :local CP1251toUTF8inURN do={                                                       # https://habr.com/ru/articles/232385/#urn
        :if (([:typeof $1]!="str") or ([:len $1]=0)) do={:return ""}
        :local cp1251 {
            "\00";"\01";"\02";"\03";"\04";"\05";"\06";"\07";"\08";"\09";"\0A";"\0B";"\0C";"\0D";"\0E";"\0F";
            "\10";"\11";"\12";"\13";"\14";"\15";"\16";"\17";"\18";"\19";"\1A";"\1B";"\1C";"\1D";"\1E";"\1F";
            "\20";"\22";"\26";"\3C";"\3E";"\5B";"\5C";"\5D";"\5E";"\60";"\7B";"\7C";"\7D";"\7E";"\7F";
            "\80";"\81";"\82";"\83";"\84";"\85";"\86";"\87";"\88";"\89";"\8A";"\8B";"\8C";"\8D";"\8E";"\8F";
            "\90";"\91";"\92";"\93";"\94";"\95";"\96";"\97";"\98";"\99";"\9A";"\9B";"\9C";"\9D";"\9E";"\9F";
            "\A0";"\A1";"\A2";"\A3";"\A4";"\A5";"\A6";"\A7";"\A8";"\A9";"\AA";"\AB";"\AC";"\AD";"\AE";"\AF";
            "\B0";"\B1";"\B2";"\B3";"\B4";"\B5";"\B6";"\B7";"\B8";"\B9";"\BA";"\BB";"\BC";"\BD";"\BE";"\BF";
            "\C0";"\C1";"\C2";"\C3";"\C4";"\C5";"\C6";"\C7";"\C8";"\C9";"\CA";"\CB";"\CC";"\CD";"\CE";"\CF";
            "\D0";"\D1";"\D2";"\D3";"\D4";"\D5";"\D6";"\D7";"\D8";"\D9";"\DA";"\DB";"\DC";"\DD";"\DE";"\DF";
            "\E0";"\E1";"\E2";"\E3";"\E4";"\E5";"\E6";"\E7";"\E8";"\E9";"\EA";"\EB";"\EC";"\ED";"\EE";"\EF";
            "\F0";"\F1";"\F2";"\F3";"\F4";"\F5";"\F6";"\F7";"\F8";"\F9";"\FA";"\FB";"\FC";"\FD";"\FE";"\FF"}
        :local utf8 {
            "00";"01";"02";"03";"04";"05";"06";"07";"08";"09";"0A";"0B";"0C";"0D";"0E";"0F";
            "10";"11";"12";"13";"14";"15";"16";"17";"18";"19";"1A";"1B";"1C";"1D";"1E";"1F";
            "20";"22";"26";"3C";"3E";"5B";"5C";"5D";"5E";"60";"7B";"7C";"7D";"7E";"7F";
            "D082";"D083";"E2809A";"D193";"E2809E";"E280A6";"E280A0";"E280A1";"E282AC";"E280B0";"D089";"E280B9";"D08A";"D08C";"D08B";"D08F";
            "D192";"E28098";"E28099";"E2809C";"E2809D";"E280A2";"E28093";"E28094";"EFBFBD";"E284A2";"D199";"E280BA";"D19A";"D19C";"D19B";"D19F";
            "C2A0";"D08E";"D19E";"D088";"C2A4";"D290";"C2A6";"C2A7";"D081";"C2A9";"D084";"C2AB";"C2AC";"534859";"C2AE";"D087";
            "C2B0";"C2B1";"D086";"D196";"D291";"C2B5";"C2B6";"C2B7";"D191";"E28496";"D194";"C2BB";"D198";"D085";"D195";"D197";
            "D090";"D091";"D092";"D093";"D094";"D095";"D096";"D097";"D098";"D099";"D09A";"D09B";"D09C";"D09D";"D09E";"D09F";
            "D0A0";"D0A1";"D0A2";"D0A3";"D0A4";"D0A5";"D0A6";"D0A7";"D0A8";"D0A9";"D0AA";"D0AB";"D0AC";"D0AD";"D0AE";"D0AF";
            "D0B0";"D0B1";"D0B2";"D0B3";"D0B4";"D0B5";"D0B6";"D0B7";"D0B8";"D0B9";"D0BA";"D0BB";"D0BC";"D0BD";"D0BE";"D0BF";
            "D180";"D181";"D182";"D183";"D184";"D185";"D186";"D187";"D188";"D189";"D18A";"D18B";"D18C";"D18D";"D18E";"D18F"}
        :local res ""; :local urn "";
        :for i from=0 to=([:len $1]-1) do={
            :local sym [:pick $1 $i ($i+1)];                                            # source symbol
            :local idx [:find $cp1251 $sym];                                            # index
            :local utf ($utf8->$idx);                                                   # target symbol
            :if ([:len $utf]=0) do={:set urn $sym}
            :if ([:len $utf]=2) do={:set urn "%$[:pick $utf 0 2]"}
            :if ([:len $utf]=4) do={:set urn "%$[:pick $utf 0 2]%$[:pick $utf 2 4]"}
            :if ([:len $utf]=6) do={:set urn "%$[:pick $utf 0 2]%$[:pick $utf 2 4]%$[:pick $utf 4 6]"}
            :set res "$res$urn";
        }
        :return $res;
    }

    # --------------------------------------------------------------------------------- # function of converting to lowercase letters
    :local LowStr do={                                                                  # https://forummikrotik.ru/viewtopic.php?f=14&t=12659&p=87224#p87224
        :if ([:typeof $1]!="str" or [:len $1]=0) do={:return ""}
        :local LowChar do={
            :local upper "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            :local lower "abcdefghijklmnopqrstuvwxyz";
            :local pos [:find $upper $1];
            :if ($pos>-1) do={:return [:pick $lower $pos]};                             # when match is found -> returning a lowercase character
            :return $1;
        }
        :local res ""; 
        :for i from=0 to=([:len $1]-1) do={:set res "$res$[$LowChar [:pick $1 $i]]"};   # formation of lowercase string
        :return $res;
    }

    # --------------------------------------------------------------------------------- # telegram messenger response parsing function
    :local MsgParser do={                                                               # https://habr.com/ru/post/482802/
        :if ([:typeof $1]!="str" or [:len $1]=0) do={:return ""}
        :local variaMod ("\"$2\"");
        :if ([:len [:find $1 $variaMod -1]]=0) do={:return "unknown"}
        :local startLoc ([:find $1 $variaMod -1]+[:len $variaMod]+1);
        :local commaLoc  [:find $1 "," $startLoc];
        :local brakeLoc  [:find $1 "}" $startLoc];
        :local endLoc $commaLoc;
        :local startSymbol [:pick $1 $startLoc];
        :if ($brakeLoc!=0 && ($commaLoc=0 or $brakeLoc<$commaLoc)) do={:set endLoc $brakeLoc}
        :if ($startSymbol="{") do={:set endLoc ($brakeLoc+1)}
        :if ($3=true) do={:set startLoc ($startLoc+1); :set endLoc ($endLoc-1)}
        :if ($endLoc<$startLoc) do={:set endLoc ($startLoc+1)}
        :return [:pick $1 $startLoc $endLoc];
    }

    # --------------------------------------------------------------------------------- # time translation function to UNIX-time
    :global DateTime2EpochDEL do={                                                      # https://forum.mikrotik.com/viewtopic.php?t=75555#p994849
        :local dTime [:tostr $1];                                                       # parses date formats: "hh:mm:ss","mmm/dd hh:mm:ss","mmm/dd/yyyy hh:mm:ss","yyyy-mm-dd hh:mm:ss","mm-dd hh:mm:ss"
        /system clock;
        :local cYear [get date]; :if ($cYear~"....-..-..") do={:set cYear [:pick $cYear 0 4]} else={:set cYear [:pick $cYear 7 11]}
        :if ([:len $dTime]=10 or [:len $dTime]=11) do={:set dTime "$dTime 00:00:00"}
        :if ([:len $dTime]=15) do={:set dTime "$[:pick $dTime 0 6]/$cYear $[:pick $dTime 7 15]"}
        :if ([:len $dTime]=14) do={:set dTime "$cYear-$[:pick $dTime 0 5] $[:pick $dTime 6 14]"}
        :if ([:len $dTime]=8) do={:set dTime "$[get date] $dTime"}
        :if ([:tostr $1]="") do={:set dTime ("$[get date] $[get time]")}
        :local vDate [:pick $dTime 0 [:find $dTime " " -1]];
        :local vTime [:pick $dTime ([:find $dTime " " -1]+1) [:len $dTime]];
        :local vGmt [get gmt-offset]; :if ($vGmt>0x7FFFFFFF) do={:set vGmt ($vGmt-0x100000000)}
        :if ($vGmt<0) do={:set vGmt ($vGmt* -1)}
        :local arrMn [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"];
        :local vdOff [:toarray "0,4,5,7,8,10"];
        :local month [:tonum [:pick $vDate ($vdOff->2) ($vdOff->3)]];
        :if ($vDate~".../../....") do={
            :set vdOff [:toarray "7,11,1,3,4,6"];
            :set month ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $vDate ($vdOff->2) ($vdOff->3)] -1]/2);
            :if ($month>12) do={:set month ($month-12)}
        }
        :local year [:pick $vDate ($vdOff->0) ($vdOff->1)]; :if ((($year-1968)%4)=0) do={:set ($arrMn->1) -1; :set ($arrMn->2) 30}
        :local toTd ((($year-1970)*365)+(($year-1968)/4)+($arrMn->$month)+([:pick $vDate ($vdOff->4) ($vdOff->5)]-1));
        :return (((((($toTd*24)+[:pick $vTime 0 2])*60)+[:pick $vTime 3 5])*60)+[:pick $vTime 6 8]-$vGmt);
    }

    # --------------------------------------------------------------------------------- # time conversion function from UNIX-time
    :global UnixToDateTimeDEL do={                                                      # https://forum.mikrotik.com/viewtopic.php?p=977170#p977170
        :local ZeroFill do={:return [:pick (100+$1) 1 3]}
        :local prMntDays [:toarray "0,0,31,59,90,120,151,181,212,243,273,304,334"];
        :local vGmt [:tonum [/system clock get gmt-offset]]; :if ($vGmt>0x7FFFFFFF) do={:set vGmt ($vGmt-0x100000000)}
        :if ($vGmt<0) do={:set vGmt ($vGmt* -1)}
        :local tzEpoch ($vGmt+[:tonum $1]);
        :if ($tzEpoch<0) do={:set tzEpoch 0};                                           # unsupported negative unix epoch
        :local yearStart (1970+($tzEpoch/31536000));
        :local tmpLeap (($yearStart-1968)/4); :if ((($yearStart-1968)%4)=0) do={:set ($prMntDays->1) -1; :set ($prMntDays->2) 30}
        :local tmpSec ($tzEpoch%31536000);
        :local tmpDays (($tmpSec/86400)-$tmpLeap);
        :if ($tmpSec<(86400*$tmpLeap) && (($yearStart-1968)%4)=0) do={
            :set tmpLeap ($tmpLeap-1); :set ($prMntDays->1) 0; :set ($prMntDays->2) 31; :set tmpDays ($tmpDays+1);
        }
        :if ($tmpSec<(86400*$tmpLeap)) do={:set yearStart ($yearStart-1); :set tmpDays ($tmpDays+365)}
        :local mnthStart 12 ; :while (($prMntDays->$mnthStart)>$tmpDays) do={:set mnthStart ($mnthStart-1)}
        :local dayStart [$ZeroFill (($tmpDays+1)-($prMntDays->$mnthStart))];
        :local timeStart (00:00:00+[:totime ($tmpSec%86400)]);
        :return "$yearStart/$[$ZeroFill $mnthStart]/$[$ZeroFill $dayStart] $timeStart";
    }

    # --------------------------------------------------------------------------------- # current time in a nice format output function
    :local CurrentTime do={
        :global DateTime2EpochDEL;
        :global UnixToDateTimeDEL;
        :return [$UnixToDateTimeDEL [$DateTime2EpochDEL]];
    }

    # ================================================================================= # main body of the script ========================
    :local nameID [$LowStr [/system identity get name]];                                # text ID of router
    :local currTime [$CurrentTime];
    :put "$currTime\tStart of TLGRM on router:\t$nameID";
    :if ([:len $scriptTlgrm]=0) do={:set scriptTlgrm true};                             # creating a script execution flag
    :if ($scriptTlgrm) do={                                                             # when script is not active ->
        :set scriptTlgrm false;
        :if ([:len $timeAct]>0) do={:put "$[$CurrentTime]\tTime executed last command:\t$[$UnixToDateTimeDEL $timeAct]"}
        :if ([:len $timeLog]>0) do={:put "$[$CurrentTime]\tTime sent last log entries:\t$[$UnixToDateTimeDEL $timeLog]"}

        # ----------------------------------------------------------------------------- # part of the script body to execute via Telegram ---
                                                                                        # https://forummikrotik.ru/viewtopic.php?p=78085
        :put "$[$CurrentTime]\t*** Stage of launch via Telegram ***";
        :local timeStmp [$DateTime2EpochDEL];
        :local urlString "https://api.telegram.org/$botID/getUpdates\?offset=-1&limit=1&allowed_updates=message";
        :local httpResp "";
        :if ([:len $timeAct]=0) do={:put "$[$CurrentTime]\tTime of last launch not found"; :set timeAct $timeStmp}
        :do {:set httpResp [/tool fetch url=$urlString as-value output=user]} on-error={}
        :if ([:len $httpResp]!=0) do={
            :local content ($httpResp->"data");
            :if ([:len $content]>30) do={
                :local msgTxt [$MsgParser $content "text" true];
                :set   msgTxt [:pick $msgTxt ([:find $msgTxt "/" -1]+1) [:len $msgTxt]];
                :if ($msgTxt~"@") do={:set msgTxt [:pick $msgTxt 0 [:find $msgTxt "@"]]}
                :local newStr ""; :local change ""; :local msgAddr "";
                :for i from=0 to=([:len $msgTxt]-1) do={
                    :local symb [:pick $msgTxt $i ($i+1)];
                    :if ($symb="_") do={:set change " "} else={:set change $symb} 
                    :set newStr "$newStr$change";
                }
                :set msgTxt $newStr;
                :if ($broadCast) do={:set msgAddr $nameID} else={
                    :set msgAddr [:pick $msgTxt 0 [:find $msgTxt " " -1]];
                    :set msgAddr [$LowStr $msgAddr];
                    :if ([:len [:find $msgTxt " "]]=0) do={:set msgAddr "$msgTxt "}
                    :put "$[$CurrentTime]\tRecipient of Telegram message:\t$msgAddr";
                    :set msgTxt [:pick $msgTxt ([:find $msgTxt $msgAddr -1]+[:len $msgAddr]+1) [:len $msgTxt]];
                }
                :if ( [:pick $msgTxt 0 1]= "\$") do={:set msgTxt [:pick $msgTxt 1 [:len $msgTxt]]}
                :if ([:pick $msgTxt 0 2]="[\$" && [:pick $msgTxt ([:len $msgTxt]-1) [:len $msgTxt]]="]") do={
                    :set msgTxt [:pick $msgTxt 2 ([:len $msgTxt]-1)];                   # skipping prefix "$"  or [$ .....]
                }
                :if ($msgAddr=$nameID or $msgAddr="forall") do={
                    :local chatID [$MsgParser [$MsgParser $content "chat"] "id"];
                    :local userNm [$MsgParser $content "username"];
                    :set timeStmp [$MsgParser $content "date"];
                    :put "$[$CurrentTime]\tSender of Telegram message:\t$userNm";
                    :put "$[$CurrentTime]\tCommand to execute:\t\t$msgTxt";
                    :local restline [];
                    :if ([:len [:find $msgTxt " "]]!=0) do={
                        :set restline [:pick $msgTxt  ([:find $msgTxt " "]+1) [:len $msgTxt]];
                        :set msgTxt [:pick $msgTxt 0 [:find $msgTxt " "]];
                    }
                    :if ($chatID=$myChatID && $timeAct<$timeStmp) do={
                        :set timeAct $timeStmp;
                        :if ([/system script environment find name=$msgTxt]!="" && $launchFnc) do={
                            :if (([/system script environment get [/system script environment find name=$msgTxt] value]="(code)")\
                                or [:len [:find [/system script environment get [/system script environment find name=$msgTxt] value] "(eval"]]>0) do={
                                :put "$[$CurrentTime]\tRight time to launch function";
                                :log warning "Telegram user $userNm launches function: $msgTxt";
                                :execute script="[:parse [\$$msgTxt $restline]]";
                            } else={
                                :put "$[$CurrentTime]\t'$msgTxt' is a global variable and is not launched";
                                :log warning "'$msgTxt' is a global variable and is not launched";
                            }
                        }
                        :if ([:pick $msgTxt 0 1]="\5C") do={                            # allow to perform emoji
                            :set msgTxt [:pick $msgTxt 1 [:len $msgTxt]];
                            :if ([:find $msgTxt "\5C"]!=0) do={
                                :local first [:pick $msgTxt 0 [:find $msgTxt "\5C"]];
                                :local after [:pick $msgTxt  ([:find $msgTxt "\5C"]+1) [:len $msgTxt]];
                                :set msgTxt "$first$after";
                            }
                        }
                        :if ([/system script find name=$msgTxt]!="" && $launchScr) do={
                            :put "$[$CurrentTime]\tRight time to activate script";
                            :log warning "Telegram user $userNm activates script: $msgTxt";
                            :execute script="[[:parse \"[:parse [/system script get $msgTxt source]] $restline\"]]";
                        }
                        :if ([/system script find name=$msgTxt]="" && [/system script environment find name=$msgTxt]="" && $launchCmd) do={
                            :put "$[$CurrentTime]\tRight time to execute command";
                            :log warning "Telegram user $userNm is trying to execute command: $msgTxt";
                            :do {:execute script="[:parse \"/$msgTxt $restline\"]"} on-error={}
                        }
                    } else={:put "$[$CurrentTime]\tWrong time to launch"}
                } else={:put "$[$CurrentTime]\tNo command found for this device"}
            } else={:put "$[$CurrentTime]\tCompletion of response from Telegram"}
        } else={:put "$[$CurrentTime]\tNot response from Telegram"}
        :delay 1s;                                                                      # time difference between command execution and log broadcast

        # ----------------------------------------------------------------------------- # part of the script body for notifications in Telegram ----
                                                                                        # https://www.reddit.com/r/mikrotik/comments/onusoj/sending_log_alerts_to_telegram/
        :put "$[$CurrentTime]\t*** Stage of broadcasting to Telegram ***";
        :local logGet [:toarray [/log find (topics~"warning" or topics~"error" or topics~"critical" or topics~"caps" or topics~"wireless"\
            or topics~"dhcp" or topics~"firewall" or message~"logged in" or message~"sntp")]]; # list of potentially interesting log entries
        :local logCnt [:len $logGet];                                                   # counter of suitable log entries
        :local tlgCnt 0;                                                                # counter of log entries sent to Telegram
        :local outMsg "";
        :if ([:len $timeLog]=0) do={
            :put "$[$CurrentTime]\tTime of the last log entry was not found";
            :set outMsg "$[/system clock get time] Telegram notification started";
            :set tlgCnt ($tlgCnt+1);
        }
        :if ($logCnt>0) do={                                                            # when log entries are available ->
            :set logCnt ($logCnt-1);                                                    # index of last log entry
            :local lastTime [$DateTime2EpochDEL [/log get [:pick $logGet $logCnt] time]]; # time of the last message
            :local unixTim  "";
            :do {
                :local tempTim [/log get [:pick $logGet $logCnt] time];                 # message time
                :set   unixTim [$DateTime2EpochDEL $tempTim];
                :local tempTpc [/log get [:pick $logGet $logCnt] topics];               # message topic
                :local tempMsg [/log get [:pick $logGet $logCnt] message];              # message body
                :local tempMac [$FindMAC $tempMsg];                                     # finding MAC address in log entry
                :local tempAdr ""; :local tempCmt ""; :local tempHst ""; :local tempDyn ""; :local tempIfc "empty"; :local tempStg "";
                :do {
                    :set tempCmt [/ip dhcp-server lease get [find mac-address=$tempMac] comment];
                    :set tempHst [/ip dhcp-server lease get [find mac-address=$tempMac] host-name];
                    :set tempAdr [/ip dhcp-server lease get [find mac-address=$tempMac status="bound"] address];
                    :set tempDyn [/ip dhcp-server lease get [find mac-address=$tempMac status="bound"] dynamic];
                    :set tempIfc [/interface bridge host get [find mac-address=$tempMac] on-interface];
                    :set tempStg [/interface wireless registration-table get [find last-ip=$tempAdr] signal-strength-ch0];
                } on-error={}
                :local preloadMessage "";
                :if ($unixTim>$timeLog) do={                                            # selection of actualing log entries ->
                    :if ($tempMac="") do={                                              # when message with missing MAC address ->
                        :set preloadMessage "$tempTim $tempMsg";
                    } else={
                        :if ($tempDyn="") do={                                          # when DHCP-server lease client is not actual ->
                            :set preloadMessage "$tempTim $tempMsg $tempHst $tempCmt inactive device";
                        } else={
                            :if (!$tempDyn && [:len $tempCmt]=0) do={                   # when message with static IP & unfamiliar MAC ->
                                :set preloadMessage "$tempTim $tempMsg $tempHst $tempAdr empty comment on DHCP-Server lease"}
# ------------------- user information output --- BEGIN -------------------
                            :if ($userInfo) do={
                                :if ($tempMsg~" assigned") do={                         # when address leasing DHCP server ->
                                    :local prefiksForLan "77_"; :local user1 "User1"; :local user2 "User2"; :local whereUser "PLACENAME";
                                    :if ($tempCmt=$user1) do={:set preloadMessage "$[($emo->"store")] $tempTim $user1 at the $whereUser"}
                                    :if ($tempCmt=$user2) do={:set preloadMessage "$[($emo->"phone")] $tempTim $user2 at the $whereUser"}
                                    :if ($tempDyn) do={:set preloadMessage "$tempTim $prefiksForLan $tempCmt +$tempIfc $tempStg $tempAdr $tempHst"}\
                                    else={:set preloadMessage "$tempTim $[($emo->"bell")] $tempCmt +$tempIfc $tempStg $tempAdr $tempHst"}
                                }
                            }
# ------------------- user information output --- END -------------------
                        }
                    }
                }
                :if ([:len $preloadMessage]!=0) do={
                    :set tlgCnt ($tlgCnt+1);
                    :set outMsg "$preloadMessage\n$outMsg";                             # attach to general message for Telegram
                    :put "$[$CurrentTime]\tAdded entry: $preloadMessage";
                }
                :set logCnt ($logCnt-1);
            } while=($unixTim>$timeLog && $logCnt> -1);
            :if ([:len $timeLog]=0 or ([:len $timeLog]>0 && $timeLog!=$lastTime && [:len $outMsg]>8)) do={
                :set timeLog $lastTime;
                :set outMsg [$CP1251toUTF8inURN $outMsg];                               # converting MESSAGE to UTF8 in URN-standart
                :if ([:len $outMsg]>4096) do={:set outMsg [:pick $outMsg 0 4096]};      # cutting MESSAGE to 4096 bytes
                :if ($tlgCnt=1) do={:set outMsg "%20$outMsg"} else={:set outMsg "%0A$outMsg"}; # solitary message for pop-up notification on phone
                :set urlString "https://api.telegram.org/$botID/sendmessage\?chat_id=$myChatID&text=$nameID:$outMsg";
                :put "$[$CurrentTime]\tGenerated string for Telegram:\r\n$urlString";
                :do {/tool fetch url=$urlString as-value output=user} on-error={}
            } else={:put "$[$CurrentTime]\tThere are no log entries to send"}
        } else={:put "$[$CurrentTime]\tNecessary log entries were not found"}
        :put "$[$CurrentTime]\tEnd of TLGRM-script";
        :set scriptTlgrm true;
        /system script environment remove [find name~"DEL"];                            # clearing memory
    } else={:put "$currTime\tScript already being executed"; :put "$currTime\tEnd of TLGRM-script"}
} on-error={                                                                            # when emergency break script ->
    :set scriptTlgrm true;
    /system script environment remove [find name~"DEL"];                                # clearing memory
    :put "Script error: something didn't work when sending a request to Telegram";
    :put "*** First, check the correctness of the values of the variables botID & myChatID ***";
}
